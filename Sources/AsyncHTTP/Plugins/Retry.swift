import Foundation

public protocol RetryStrategy: AnyObject {
    func retryDelay(for error: Error, numberOfPreviousAttempts: Int) -> TimeInterval?
}

public enum RetryStrategyOption: HTTPRequestOption {
    public static let defaultValue: RetryStrategyWrapper? = nil
}

public struct RetryStrategyWrapper: Hashable {
    let wrapped: RetryStrategy
    private var objectID: ObjectIdentifier {
        ObjectIdentifier(type(of: wrapped))
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(objectID)
    }

    public static func == (lhs: RetryStrategyWrapper, rhs: RetryStrategyWrapper) -> Bool {
        lhs.objectID == rhs.objectID
    }
}

extension HTTPRequest {
    public var retryStrategy: RetryStrategy? {
        get { self[option: RetryStrategyOption.self]?.wrapped }
        set { self[option: RetryStrategyOption.self] = newValue.map(RetryStrategyWrapper.init) }
    }
}

public final class Backoff: RetryStrategy {
    private let strategyImplementation: (_ error: Error, _ numberOfPreviousAttempts: Int) -> TimeInterval?

    init(strategyImplementation: @escaping (Error, Int) -> TimeInterval?) {
        self.strategyImplementation = strategyImplementation
    }

    public func retryDelay(for error: Error, numberOfPreviousAttempts: Int) -> TimeInterval? {
        strategyImplementation(error, numberOfPreviousAttempts)
    }

    public func filter(_ condition: @escaping (Error) -> Bool) -> Backoff {
        Backoff { [strategyImplementation] error, numberOfPreviousAttempts in
            if condition(error) {
                return strategyImplementation(error, numberOfPreviousAttempts)
            } else {
                return nil
            }
        }
    }
}

extension RetryStrategy where Self == Backoff {
    public static func immediately(maximumNumberOfAttempts: Int) -> Backoff {
        .constant(delay: 0, maximumNumberOfAttempts: maximumNumberOfAttempts)
    }
    public static func constant(delay: TimeInterval, maximumNumberOfAttempts: Int) -> Backoff {
        Backoff { _, numberOfPreviousAttempts in
            guard numberOfPreviousAttempts < maximumNumberOfAttempts else { return nil }
            return delay
        }
    }
    public static func exponential(delay: TimeInterval, base: Int = 2, maximumNumberOfAttempts: Int) -> Backoff {
        Backoff { _, numberOfPreviousAttempts in
            guard numberOfPreviousAttempts < maximumNumberOfAttempts else { return nil }
            return pow(Double(base), Double(numberOfPreviousAttempts - 1))
        }
    }
    public static func fibonacci(maximumNumberOfAttempts: Int) -> Backoff {
        return Backoff { _, numberOfPreviousAttempts in
            func fibonacci(n: Int) -> Int {
                switch n {
                    case ...0: return 0
                    case 1: return 1
                    default: return fibonacci(n: n - 2) + fibonacci(n: n - 1)
                }
            }
            return Double(fibonacci(n: numberOfPreviousAttempts))
        }
    }
}

extension Loader {
#if compiler(>=5.7)
    @_disfavoredOverload
    public func applyRetryStrategy(default: RetryStrategy? = nil) -> some Loader<Input, Output> {
        Loaders.ApplyRetryStrategy(loader: self) { _ in `default` }
    }
#endif

    public func applyRetryStrategy(default: RetryStrategy? = nil) -> Loaders.ApplyRetryStrategy<Self> {
        .init(loader: self) { _ in `default` }
    }
}

extension Loader where Input == HTTPRequest {
#if compiler(>=5.7)
    @_disfavoredOverload
    public func applyRetryStrategy(default: RetryStrategy? = nil) -> some Loader<HTTPRequest, Output> {
        Loaders.ApplyRetryStrategy(loader: self) { $0.retryStrategy ?? `default` }
    }
#endif

    public func applyRetryStrategy(default: RetryStrategy? = nil) -> Loaders.ApplyRetryStrategy<Self> {
        .init(loader: self) { $0.retryStrategy ?? `default` }
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    public func applyRetryStrategy(default: RetryStrategy? = nil, clock: some Clock<Duration>) -> Loaders.ApplyRetryStrategy<Self> {
        .init(loader: self) { $0.retryStrategy ?? `default` } wait: { try await clock.sleep(seconds: $0) }
    }
}

extension Loaders {
    public struct ApplyRetryStrategy<Wrapped: Loader>: CompositeLoader {
        private let loader: Wrapped
        private let retryStrategy: (Input) -> RetryStrategy?
        private let numberOfPreviousAttempts: Int
        private let wait: (TimeInterval) async throws -> Void

        init(loader: Wrapped,
             retryStrategy: @escaping (Input) -> RetryStrategy? = { _ in nil },
             numberOfPreviousAttempts: Int = 0,
             wait: @escaping (TimeInterval) async throws -> Void = Task.sleep) {
            self.loader = loader
            self.retryStrategy = retryStrategy
            self.numberOfPreviousAttempts = numberOfPreviousAttempts
            self.wait = wait
        }

        public func load(_ input: Wrapped.Input) async throws -> Wrapped.Output {
            do {
                return try await loader.load(input)
            } catch {
                guard let delay = retryStrategy(input)?.retryDelay(for: error, numberOfPreviousAttempts: numberOfPreviousAttempts) else {
                    throw error
                }
                try await wait(delay)
                let loader = ApplyRetryStrategy(loader: loader, retryStrategy: retryStrategy, numberOfPreviousAttempts: numberOfPreviousAttempts + 1)
                return try await loader.load(input)
            }
        }
    }
}
