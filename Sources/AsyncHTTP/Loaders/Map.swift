import Foundation

extension Loader {
    public func map<NewOutput>(_ transform: @escaping (Output) throws -> NewOutput) -> Loaders.Map<Self, NewOutput> {
        Loaders.Map<Self, NewOutput>(self, transform)
    }
}

extension Loaders {
    public struct Map<Upstream: Loader, Output>: Loader {
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
}

extension Loaders.Map: HTTPLoader where Input == HTTPRequest, Output == HTTPResponse {}
