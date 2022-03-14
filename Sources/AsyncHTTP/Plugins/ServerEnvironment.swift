import Foundation

public struct ServerEnvironment: Hashable {
    public var host: String
    public var pathPrefix: String
    public var headers: [HTTPHeader<String>: String]
    public var query: [URLQueryItem]?

    public init(host: String,
                pathPrefix: String = "",
                headers: [HTTPHeader<String>: String] = [:],
                query: [URLQueryItem]? = nil) {
        self.host = host
        self.pathPrefix = pathPrefix
        self.headers = headers
        self.query = query
    }

    func apply(to components: URLComponents) -> URLComponents {
        var urlComponents = components
        urlComponents.host = host
        urlComponents.path = pathPrefix.prefixIfNeeded(with: "/") + urlComponents.path.prefixIfNeeded(with: "/")
        urlComponents.queryItems = query + urlComponents.queryItems
        return urlComponents
    }

    func apply(to headers: [HTTPHeader<String>: String]) -> [HTTPHeader<String>: String] {
        headers.merging(self.headers) { old, _ in old }
    }
}

public enum ServerEnvironmentOption: HTTPRequestOption {
    public static let defaultValue: ServerEnvironment? = nil
}

extension HTTPRequest {
    public var serverEnvironment: ServerEnvironment? {
        get { self[option: ServerEnvironmentOption.self] }
        set { self[option: ServerEnvironmentOption.self] = newValue }
    }
}

extension Loader where Input == HTTPRequest {
    public func applyServerEnvironment(defaultEnvironment: ServerEnvironment? = nil) -> Loaders.ApplyServerEnvironment<Self> {
        .init(loader: self)
    }
}

extension Loaders {
    public struct ApplyServerEnvironment<Wrapped: Loader>: CompositeLoader where Wrapped.Input == HTTPRequest {
        private let loader: Wrapped
        private let defaultEnvironment: ServerEnvironment?

        init(loader: Wrapped,
             defaultEnvironment: ServerEnvironment? = nil) {
            self.loader = loader
            self.defaultEnvironment = defaultEnvironment
        }

        public func load(_ request: HTTPRequest) async throws -> Wrapped.Output {
            return try await loader.load(request.configured { request in
                request.serverEnvironment = request.serverEnvironment ?? defaultEnvironment
            })
        }
    }
}

extension Loaders.ApplyServerEnvironment: HTTPLoader where Output == HTTPResponse {}

private func +(lhs: [URLQueryItem]?, rhs: [URLQueryItem]?) -> [URLQueryItem]? {
    switch (lhs, rhs) {
        case let (.some(lhs), .some(rhs)):
            return lhs + rhs
        case let (.none, .some(rhs)):
            return rhs
        case let (.some(lhs), .none):
            return lhs
        case (.none, .none):
            return nil
    }
}

private extension String {
    func prefixIfNeeded(with prefix: String) -> String {
        if hasPrefix(prefix) {
            return self
        }
        return prefix + self
    }
}
