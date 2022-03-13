import Foundation

public struct HTTPRequestIdentifier: Equatable, Hashable {
    public let id: String
}

public enum HTTPRequestIdentifierOption: HTTPRequestOption {
    public static let defaultValue: HTTPRequestIdentifier? = nil
}

extension HTTPRequest {
    public internal(set) var id: HTTPRequestIdentifier? {
        get { self[option: HTTPRequestIdentifierOption.self] }
        set { self[option: HTTPRequestIdentifierOption.self] = newValue }
    }
}

extension Loader {
    public func identified(identifier: @escaping (HTTPRequest) -> String = generateUUID) -> Loaders.ApplyRequestIdentity<Self> where Input == HTTPRequest {
        .init(loader: self, identifier: identifier)
    }
}

public let generateUUID: (HTTPRequest) -> String = { _ in UUID().uuidString }

extension Loaders {
    public struct ApplyRequestIdentity<Wrapped: Loader>: CompositeLoader where Wrapped.Input == HTTPRequest {

        private let loader: Wrapped
        private let identifier: (HTTPRequest) -> String

        init(loader: Wrapped,
             identifier: @escaping (HTTPRequest) -> String = generateUUID) {
            self.loader = loader
            self.identifier = identifier
        }

        public func load(_ request: HTTPRequest) async throws -> Wrapped.Output {
            var modifiedRequest = request
            modifiedRequest.id = .init(id: identifier(request))
            return try await loader.load(modifiedRequest)
        }
    }
}

extension Loaders.ApplyRequestIdentity: HTTPLoader where Output == HTTPResponse {}
