import Foundation

extension Loader {
#if compiler(>=5.7)
    @_disfavoredOverload
    public func map<NewOutput>(_ transform: @escaping (Output) throws -> NewOutput) -> some Loader<Input, NewOutput> {
        Loaders.ThrowingMap(self, transform)
    }
#endif

    public func map<NewOutput>(_ transform: @escaping (Output) throws -> NewOutput) -> Loaders.ThrowingMap<Self, NewOutput> {
        .init(self, transform)
    }

#if compiler(>=5.7)
    @_disfavoredOverload
    public func map<NewOutput>(_ transform: @escaping (Output) -> NewOutput) -> some Loader<Input, NewOutput> {
        Loaders.Map(self, transform)
    }
#endif

    public func map<NewOutput>(_ transform: @escaping (Output) -> NewOutput) -> Loaders.Map<Self, NewOutput> {
        .init(self, transform)
    }
}

extension Loaders {
    public struct ThrowingMap<Upstream: Loader, Output>: Loader {
        public typealias Input = Upstream.Input

        private let upstream: Upstream
        private let transform: (Upstream.Output) throws -> Output

        init(_ upstream: Upstream, _ transform: @escaping (Upstream.Output) throws -> Output) {
            self.upstream = upstream
            self.transform = transform
        }

        public func load(_ input: Input) async throws -> Output {
            try await transform(upstream.load(input))
        }
    }

    public struct Map<Upstream: Loader, Output>: Loader {
        public typealias Input = Upstream.Input

        private let upstream: Upstream
        private let transform: (Upstream.Output) -> Output

        init(_ upstream: Upstream, _ transform: @escaping (Upstream.Output) -> Output) {
            self.upstream = upstream
            self.transform = transform
        }

        public func load(_ input: Input) async rethrows -> Output {
            try await transform(upstream.load(input))
        }
    }
}
