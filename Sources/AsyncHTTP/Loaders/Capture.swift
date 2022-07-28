import Foundation

extension Loader {
#if compiler(>=5.7)
    @_disfavoredOverload
    public func capture(input: @escaping (Input) -> Void) -> some Loader<Input, Output> {
        Loaders.Capture(self, captureInput: input)
    }
#endif

    public func capture(input: @escaping (Input) -> Void) -> Loaders.Capture<Self> {
        .init(self, captureInput: input)
    }

#if compiler(>=5.7)
    @_disfavoredOverload
    public func capture(output: @escaping (Input, Output) -> Void) -> some Loader<Input, Output> {
        Loaders.Capture(self, captureOutput: output)
    }
#endif

    public func capture(output: @escaping (Input, Output) -> Void) -> Loaders.Capture<Self> {
        .init(self, captureOutput: output)
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

        public func load(_ input: Input) async rethrows -> Output {
            captureInput?(input)
            let output = try await original.load(input)
            captureOutput?(input, output)
            return output
        }
    }
}
