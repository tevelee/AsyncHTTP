import Foundation

extension Loader {
    public func flatMap<NewLoader: Loader>(_ transform: @escaping (Output) throws -> NewLoader) -> Loaders.FlatMap<Self, NewLoader> where Output == NewLoader.Input {
        Loaders.FlatMap<Self, NewLoader>(self, transform)
    }
}

extension Loaders {
    public struct FlatMap<Upstream: Loader, NewLoader: Loader>: Loader where NewLoader.Input == Upstream.Output {
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
}
