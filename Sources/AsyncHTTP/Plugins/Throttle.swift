import Foundation

extension Loader {
#if compiler(>=5.7)
    @_disfavoredOverload
    public func throttle(maximumNumberOfRequests: UInt = UInt.max) -> some Loader<Input, Output> where Input: Hashable {
        Loaders.Throttle(loader: self, maximumNumberOfRequests: maximumNumberOfRequests)
    }
#endif

    public func throttle(maximumNumberOfRequests: UInt = UInt.max) -> Loaders.Throttle<Self> where Input: Hashable {
        .init(loader: self, maximumNumberOfRequests: maximumNumberOfRequests)
    }
}

extension Loaders {
    public actor Throttle<Wrapped: Loader>: CompositeLoader where Wrapped.Input: Hashable {
        private let loader: Wrapped
        public let maximumNumberOfRequests: UInt
        @Published private var currentlyActiveNumberOfRequests: UInt = 0

        public init(loader: Wrapped,
                    maximumNumberOfRequests: UInt = UInt.max) {
            self.loader = loader
            self.maximumNumberOfRequests = maximumNumberOfRequests
        }

        public func load(_ input: Wrapped.Input) async throws -> Wrapped.Output {
            currentlyActiveNumberOfRequests += 1
            defer { currentlyActiveNumberOfRequests -= 1 }
            for await count in $currentlyActiveNumberOfRequests where count <= maximumNumberOfRequests {
                break
            }
            return try await loader.load(input)
        }
    }
}

@propertyWrapper
final class Published<Element>: AsyncSequence {
    typealias AsyncIterator = AsyncStream<Element>.Iterator

    var wrappedValue: Element {
        willSet {
            continuation?.yield(newValue)
        }
    }
    var projectedValue: AsyncStream<Element> { stream! }
    private var stream: AsyncStream<Element>?
    private var continuation: AsyncStream<Element>.Continuation?

    init(wrappedValue: Element) {
        self.wrappedValue = wrappedValue
        self.stream = AsyncStream { [weak self] (continuation: AsyncStream<Element>.Continuation) in
            self?.continuation = continuation
        }
    }

    func finish() {
        continuation?.finish()
    }

    func makeAsyncIterator() -> AsyncStream<Element>.Iterator {
        projectedValue.makeAsyncIterator()
    }
}
