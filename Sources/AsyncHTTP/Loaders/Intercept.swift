import Foundation

extension Loader {
#if compiler(>=5.7)
    @_disfavoredOverload
    public func intercept(transform: @escaping (inout Input) -> Void) -> some Loader<Input, Output> {
        Loaders.Intercept(self, transform: transform)
    }
#endif

    public func intercept(transform: @escaping (inout Input) -> Void) -> Loaders.Intercept<Self> {
        .init(self, transform: transform)
    }
}

extension Loaders {
    public struct Intercept<Wrapped: Loader>: CompositeLoader {
        public typealias Input = Wrapped.Input
        public typealias Output = Wrapped.Output

        private let original: Wrapped
        private let transform: ((inout Input) -> Void)?

        init(_ original: Wrapped,
             transform: ((inout Input) -> Void)? = nil) {
            self.original = original
            self.transform = transform
        }

        public func load(_ input: Input) async rethrows -> Output {
            var modified = input
            transform?(&modified)
            return try await original.load(modified)
        }
    }
}
