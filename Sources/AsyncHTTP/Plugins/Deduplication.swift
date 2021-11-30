import Foundation

extension Loader {
    public func deduplicate() -> Loaders.Deduplicate<Self> where Input: Hashable {
        .init(loader: self)
    }
}

extension Loaders {
    public actor Deduplicate<Wrapped: Loader>: CompositeLoader where Wrapped.Input: Hashable {
        private let loader: Wrapped

        private var pendingRequests: [Input: Task<Output, Error>] = [:]

        init(loader: Wrapped) {
            self.loader = loader
        }

        public func load(_ input: Wrapped.Input) async throws -> Wrapped.Output {
            if let task = pendingRequests[input] {
                return try await task.value
            }
            let task = Task {
                try await loader.load(input)
            }
            pendingRequests[input] = task
            let response = try await task.value
            pendingRequests[input] = nil
            return response
        }
    }
}

extension Loaders.Deduplicate: HTTPLoader where Input == HTTPRequest, Output == HTTPResponse {}
