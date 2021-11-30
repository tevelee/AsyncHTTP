import Foundation

extension Loader {
    public func map<NewOutput>(_ transform: @escaping (Output) throws -> NewOutput) -> Loaders.Map<Self, NewOutput> {
        Loaders.Map<Self, NewOutput>(self, transform)
    }
}

extension Loaders {
    public struct Map<Downstream: Loader, Output>: Loader {
        public typealias Input = Downstream.Input

        private let downstream: Downstream
        private let transform: (Downstream.Output) throws -> Output

        init(_ downstrean: Downstream, _ transform: @escaping (Downstream.Output) throws -> Output) {
            self.downstream = downstrean
            self.transform = transform
        }

        public func load(_ input: Input) async throws -> Output {
            try await transform(downstream.load(input))
        }
    }
}
