import Foundation

extension Loader where Input == URLRequest, Output == (Data, URLResponse) {
    public func http(modify: ((HTTPRequest, inout URLRequest) -> Void)? = nil) -> Loaders.HTTP<Self> { .init(loader: self, modify: modify) }
}

public protocol HTTPLoader: Loader where Input == HTTPRequest, Output == HTTPResponse {}

extension Loaders {
    public struct HTTP<Wrapped: Loader>: CompositeLoader, HTTPLoader where Wrapped.Input == URLRequest, Wrapped.Output == (Data, URLResponse) {
        private let loader: Wrapped
        private let modify: ((HTTPRequest, inout URLRequest) -> Void)?

        public init(loader: Wrapped, modify: ((HTTPRequest, inout URLRequest) -> Void)? = nil) {
            self.loader = loader
            self.modify = modify
        }

        public func load(_ request: HTTPRequest) async throws -> HTTPResponse {
            guard var urlRequest = request.urlRequest else {
                throw Self.Error.invalidRequest
            }
            modify?(request, &urlRequest)
            let (data, response) = try await loader.load(urlRequest)

            guard let response = response as? HTTPURLResponse else {
                throw Self.Error.notHTTPURLResponse
            }

            return HTTPResponse(request: request, response: response, body: data)
        }

        public enum Error: Swift.Error {
            case invalidRequest
            case notHTTPURLResponse
        }
    }
}
