import Foundation

public struct Timeout: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral, Equatable, Hashable {
    public var maximumDuration: TimeInterval

    public init(maximumDuration: TimeInterval) {
        self.maximumDuration = maximumDuration
    }

    public init(maximumDuration: Measurement<UnitDuration>) {
        self.maximumDuration = maximumDuration.converted(to: .seconds).value
    }

    public init?(maximumDuration: DispatchTimeInterval) {
        guard let duration = TimeInterval(dispatchTimeInterval: maximumDuration) else {
            return nil
        }
        self.maximumDuration = duration
    }

    public init(floatLiteral value: FloatLiteralType) {
        self.init(maximumDuration: value)
    }

    public init(integerLiteral value: IntegerLiteralType) {
        self.init(maximumDuration: TimeInterval(value))
    }
}

public enum TimeoutOption: HTTPRequestOption {
    public static let defaultValue: Timeout? = nil
}

extension HTTPRequest {
    public var timeout: Timeout? {
        get { self[option: TimeoutOption.self] }
        set { self[option: TimeoutOption.self] = newValue }
    }
}

extension Loader {
#if compiler(>=5.7)
    @_disfavoredOverload
    public func applyTimeout(default: Timeout? = nil) -> some Loader<Input, Output> {
        Loaders.ApplyTimeout(loader: self) { _ in `default` }
    }
#endif

    public func applyTimeout(default: Timeout? = nil) -> Loaders.ApplyTimeout<Self> {
        .init(loader: self) { _ in `default` }
    }
}

extension Loader where Input == HTTPRequest {
#if compiler(>=5.7)
    @_disfavoredOverload
    public func applyTimeout(default: Timeout? = nil) -> some Loader<HTTPRequest, Output> {
        Loaders.ApplyTimeout(loader: self) { $0.timeout ?? `default` }
    }
#endif

    public func applyTimeout(default: Timeout? = nil) -> Loaders.ApplyTimeout<Self> {
        .init(loader: self) { $0.timeout ?? `default` }
    }

    @available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
    public func applyTimeout(default: Timeout? = nil, clock: some Clock<Duration>) -> Loaders.ApplyTimeout<Self> {
        .init(loader: self) { $0.timeout ?? `default` } wait: { try await clock.sleep(seconds: $0) }
    }
}

extension Loaders {
    public struct ApplyTimeout<Wrapped: Loader>: CompositeLoader {
        private let loader: Wrapped
        private let timeout: (Input) -> Timeout?
        private let wait: (TimeInterval) async throws -> Void

        init(loader: Wrapped,
             timeout: @escaping (Input) -> Timeout? = { _ in nil },
             wait: @escaping (TimeInterval) async throws -> Void = Task.sleep) {
            self.loader = loader
            self.timeout = timeout
            self.wait = wait
        }

        public func load(_ input: Wrapped.Input) async throws -> Wrapped.Output {
            let task = Task {
                try await loader.load(input)
            }
            if let timeout = timeout(input) {
                Task.detached {
                    try await wait(timeout.maximumDuration)
                    task.cancel()
                }
            }
            return try await task.value
        }
    }
}

private extension TimeInterval {
    init?(dispatchTimeInterval: DispatchTimeInterval) {
        switch dispatchTimeInterval {
            case .seconds(let value):
                self = Double(value)
            case .milliseconds(let value):
                self = Double(value) / 1_000
            case .microseconds(let value):
                self = Double(value) / 1_000_000
            case .nanoseconds(let value):
                self = Double(value) / 1_000_000_000
            case .never:
                return nil
            default:
                return nil
        }
    }
}
