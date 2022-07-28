import Foundation

extension Loader {
#if compiler(>=5.7)
    @_disfavoredOverload
    public func pipe<Other: Loader>(_ other: Other) -> some Loader<Input, Other.Output> where Output == Other.Input {
        Loaders.Pipe(self, other)
    }
#endif

    public func pipe<Other: Loader>(_ other: Other) -> Loaders.Pipe<Self, Other> where Output == Other.Input {
        .init(self, other)
    }
}

extension Loaders {
    public struct Pipe<Upstream: Loader, Downstream: Loader>: Loader where Upstream.Output == Downstream.Input {
        public typealias Input = Upstream.Input
        public typealias Output = Downstream.Output

        private let upstream: Upstream
        private let downstream: Downstream

        init(_ upstream: Upstream, _ downstream: Downstream) {
            self.upstream = upstream
            self.downstream = downstream
        }

        public func load(_ input: Input) async rethrows -> Output {
            try await downstream.load(upstream.load(input))
        }
    }
}
