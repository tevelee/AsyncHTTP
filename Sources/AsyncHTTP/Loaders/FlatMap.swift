import Foundation

extension Loader {
    public func flatMap<NewOutput>(_ transform: @escaping (Output) throws -> Result<NewOutput, Error>) -> Loaders.FlatMap<Self, NewOutput> {
        Loaders.FlatMap<Self, NewOutput>(self, transform)
    }
}

extension Loaders {
    public struct FlatMap<Downstream: Loader, Output>: Loader {
        public typealias Input = Downstream.Input

        private let downstream: Downstream
        private let transform: (Downstream.Output) throws -> Result<Output, Error>

        init(_ downstrean: Downstream, _ transform: @escaping (Downstream.Output) throws -> Result<Output, Error>) {
            self.downstream = downstrean
            self.transform = transform
        }

        public func load(_ input: Input) async throws -> Output {
            let output = try await downstream.load(input)
            return try transform(output).get()
        }
    }
}
