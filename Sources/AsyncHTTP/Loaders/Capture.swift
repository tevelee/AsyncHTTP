import Foundation

extension Loader {
    public func capture(input: @escaping (Input) -> Void) -> Loaders.Capture<Self> {
        Loaders.Capture<Self>(self, captureInput: input)
    }

    public func capture(output: @escaping (Input, Output) -> Void) -> Loaders.Capture<Self> {
        Loaders.Capture<Self>(self, captureOutput: output)
    }
}

extension Loaders {
    public struct Capture<Wrapped: Loader>: CompositeLoader {
        public typealias Input = Wrapped.Input
        public typealias Output = Wrapped.Output

        private let original: Wrapped
        private let captureInput: ((Input) -> Void)?
        private let captureOutput: ((Input, Output) -> Void)?

        init(_ original: Wrapped,
             captureInput: ((Input) -> Void)? = nil,
             captureOutput: ((Input, Output) -> Void)? = nil) {
            self.original = original
            self.captureInput = captureInput
            self.captureOutput = captureOutput
        }

        public func load(_ input: Input) async throws -> Output {
            captureInput?(input)
            let output = try await original.load(input)
            captureOutput?(input, output)
            return output
        }
    }
}
