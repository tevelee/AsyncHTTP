import Foundation

extension Loader {
    public func delay(seconds: TimeInterval) -> Loaders.Delay<Self> {
        .init(loader: self, seconds: seconds)
    }
}

extension Loaders {
    public struct Delay<Wrapped: Loader>: CompositeLoader {
        private let loader: Wrapped
        private let duration: TimeInterval
        private let wait: (TimeInterval) async throws -> Void

        init(loader: Wrapped,
             seconds duration: TimeInterval,
             wait: @escaping (TimeInterval) async throws -> Void = { try await Task.sleep(seconds: $0) }) {
            self.loader = loader
            self.duration = duration
            self.wait = wait
        }

        public func load(_ input: Wrapped.Input) async throws -> Wrapped.Output {
            try await wait(duration)
            return try await self.load(input)
        }
    }
}

extension Loaders.Delay: HTTPLoader where Input == HTTPRequest, Output == HTTPResponse {}
