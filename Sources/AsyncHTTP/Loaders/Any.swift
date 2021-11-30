import Foundation

public typealias AnyLoader<Input, Output> = Loaders.`Any`<Input, Output>

extension Loaders {
    public struct `Any`<Input, Output>: Loader {
        private let block: (Input) async throws -> Output

        public init(load block: @escaping (Input) async throws -> Output) {
            self.block = block
        }

        public func load(_ input: Input) async throws -> Output {
            try await block(input)
        }

        public func eraseToAnyLoader() -> Self {
            self
        }
    }
}

extension Loader {
    public func eraseToAnyLoader() -> AnyLoader<Input, Output> {
        AnyLoader(load: load)
    }
}
