import Foundation

extension Loader where Input == URLRequest, Output == (Data, URLResponse) {
    public var http: Loaders.HTTP<Self> { .init(loader: self) }
}

public protocol HTTPLoader: Loader where Input == HTTPRequest, Output == HTTPResponse {}

extension Loaders {
    public struct HTTP<Wrapped: Loader>: CompositeLoader, HTTPLoader where Wrapped.Input == URLRequest, Wrapped.Output == (Data, URLResponse) {
        private let loader: Wrapped

        public init(loader: Wrapped) {
            self.loader = loader
        }

        public func load(_ request: HTTPRequest) async throws -> HTTPResponse {
            guard let urlRequest = request.urlRequest else {
                throw Self.Error.invalidRequest
            }
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
