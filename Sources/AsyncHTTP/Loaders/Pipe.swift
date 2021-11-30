import Foundation

extension Loader {
    public func pipe<Other: Loader>(_ other: Other) -> Loaders.Pipe<Self, Other> {
        Loaders.Pipe(self, other)
    }
}

extension Loaders {
    public struct Pipe<Downstream: Loader, Upstream: Loader>: Loader where Downstream.Output == Upstream.Input {
        public typealias Input = Downstream.Input
        public typealias Output = Upstream.Output

        private let downstream: Downstream
        private let upstream: Upstream

        init(_ downstrean: Downstream, _ upstream: Upstream) {
            self.downstream = downstrean
            self.upstream = upstream
        }

        public func load(_ input: Input) async throws -> Output {
            try await upstream.load(downstream.load(input))
        }
    }
}
