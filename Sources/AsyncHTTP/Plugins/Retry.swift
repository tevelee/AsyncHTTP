import Foundation

public protocol RetryStrategy: AnyObject {
    func retryDelay(for result: Error, numberOfPreviousAttempts: Int) -> TimeInterval?
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
    private let strategyImplementation: (_ numberOfPreviousAttempts: Int) -> TimeInterval?

    init(strategyImplementation: @escaping (Int) -> TimeInterval?) {
        self.strategyImplementation = strategyImplementation
    }

    public func retryDelay(for result: Error, numberOfPreviousAttempts: Int) -> TimeInterval? {
        strategyImplementation(numberOfPreviousAttempts)
    }
}

extension RetryStrategy where Self == Backoff {
    public static func immediately(maximumNumberOfAttempts: Int) -> Backoff {
        .constant(delay: 0, maximumNumberOfAttempts: maximumNumberOfAttempts)
    }
    public static func constant(delay: TimeInterval, maximumNumberOfAttempts: Int) -> Backoff {
        Backoff { numberOfPreviousAttempts in
            guard numberOfPreviousAttempts < maximumNumberOfAttempts else { return nil }
            return delay
        }
    }
    public static func exponential(delay: TimeInterval, base: Int = 2, maximumNumberOfAttempts: Int) -> Backoff {
        Backoff { numberOfPreviousAttempts in
            guard numberOfPreviousAttempts < maximumNumberOfAttempts else { return nil }
            return pow(Double(base), Double(numberOfPreviousAttempts - 1))
        }
    }
    public static func fibonacci(maximumNumberOfAttempts: Int) -> Backoff {
        return Backoff { numberOfPreviousAttempts in
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

@available(iOS 15.0, macOS 12.0, *)
extension Loader {
    @available(iOS 15.0, macOS 12.0, *)
    public func applyRetryStrategy(default: RetryStrategy? = nil) -> Loaders.ApplyRetryStrategy<Self> {
        .init(loader: self) { _ in `default` }
    }

    @available(iOS 15.0, macOS 12.0, *)
    public func applyRetryStrategy(default: RetryStrategy? = nil) -> Loaders.ApplyRetryStrategy<Self> where Input == HTTPRequest {
        .init(loader: self) { $0.retryStrategy ?? `default` }
    }
}

extension Loaders {
    @available(iOS 15.0, macOS 12.0, *)
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

@available(iOS 15.0, macOS 12.0, *)
extension Loaders.ApplyRetryStrategy: HTTPLoader where Input == HTTPRequest, Output == HTTPResponse {}
