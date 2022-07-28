import Foundation

extension Loader {
#if compiler(>=5.7)
    @_disfavoredOverload
    public func flatMap<NewLoader: Loader>(_ transform: @escaping (Output) throws -> NewLoader) -> some Loader<Input, NewLoader.Output> where Output == NewLoader.Input {
        Loaders.ThrowingFlatMap(self, transform)
    }
#endif

    public func flatMap<NewLoader: Loader>(_ transform: @escaping (Output) throws -> NewLoader) -> Loaders.ThrowingFlatMap<Self, NewLoader> where Output == NewLoader.Input {
        .init(self, transform)
    }

#if compiler(>=5.7)
    @_disfavoredOverload
    public func flatMap<NewLoader: Loader>(_ transform: @escaping (Output) -> NewLoader) -> some Loader<Input, NewLoader.Output> where Output == NewLoader.Input {
        Loaders.FlatMap(self, transform)
    }
#endif

    public func flatMap<NewLoader: Loader>(_ transform: @escaping (Output) -> NewLoader) -> Loaders.FlatMap<Self, NewLoader> where Output == NewLoader.Input {
        .init(self, transform)
    }
}

extension Loaders {
    public struct ThrowingFlatMap<Upstream: Loader, NewLoader: Loader>: Loader where NewLoader.Input == Upstream.Output {
        public typealias Input = Upstream.Input

        private let upstream: Upstream
        private let transform: (Upstream.Output) throws -> NewLoader

        init(_ upstream: Upstream, _ transform: @escaping (Upstream.Output) throws -> NewLoader) {
            self.upstream = upstream
            self.transform = transform
        }

        public func load(_ input: Input) async throws -> NewLoader.Output {
            let output = try await upstream.load(input)
            return try await transform(output).load(output)
        }
    }

    public struct FlatMap<Upstream: Loader, NewLoader: Loader>: Loader where NewLoader.Input == Upstream.Output {
        public typealias Input = Upstream.Input

        private let upstream: Upstream
        private let transform: (Upstream.Output) -> NewLoader

        init(_ upstream: Upstream, _ transform: @escaping (Upstream.Output) -> NewLoader) {
            self.upstream = upstream
            self.transform = transform
        }

        public func load(_ input: Input) async rethrows -> NewLoader.Output {
            let output = try await upstream.load(input)
            return try await transform(output).load(output)
        }
    }
}
