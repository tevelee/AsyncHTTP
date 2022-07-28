import Foundation

extension Loader {
#if compiler(>=5.7)
    @_disfavoredOverload
    public func pullback<NewInput>(transform: @escaping (NewInput) -> Input) -> some Loader<NewInput, Output> {
        Loaders.Pullback(self, transform)
    }
#endif

    public func pullback<NewInput>(transform: @escaping (NewInput) -> Input) -> Loaders.Pullback<Self, NewInput> {
        .init(self, transform)
    }
}

extension Loaders {
    public struct Pullback<Downstream: Loader, Input>: Loader {
        public typealias Output = Downstream.Output

        private let downstream: Downstream
        private let transform: (Input) -> Downstream.Input

        init(_ downstream: Downstream, _ transform: @escaping (Input) -> Downstream.Input) {
            self.downstream = downstream
            self.transform = transform
        }

        public func load(_ input: Input) async rethrows -> Output {
            try await downstream.load(transform(input))
        }
    }
}
