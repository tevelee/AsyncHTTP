import Foundation

extension Loader {
    public func pullback<NewInput>(transform: @escaping (NewInput) -> Input) -> Loaders.Pullback<Self, NewInput> {
        Loaders.Pullback<Self, NewInput>(self, transform)
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

        public func load(_ input: Input) async throws -> Output {
            try await downstream.load(transform(input))
        }
    }
}
