import Foundation

public struct HTTPRequestIdentifier: Equatable, Hashable {
    let id: String
}

public enum HTTPRequestIdentifierOption: HTTPRequestOption {
    public static let defaultValue: HTTPRequestIdentifier? = nil
}

extension HTTPRequest: Identifiable {
    internal var identity: HTTPRequestIdentifier? {
        get { self[option: HTTPRequestIdentifierOption.self] }
        set { self[option: HTTPRequestIdentifierOption.self] = newValue }
    }

    public var id: String? {
        identity?.id
    }
}

extension Loader {
    public func identifyRequests(generateIdentifier: @escaping (HTTPRequest) -> String = generateUUID) -> Loaders.ApplyRequestIdentity<Self> where Input == HTTPRequest {
        .init(loader: self, generateIdentifier: generateIdentifier)
    }
}

public let generateUUID: (HTTPRequest) -> String = { _ in UUID().uuidString }

extension Loaders {
    public struct ApplyRequestIdentity<Wrapped: Loader>: CompositeLoader where Wrapped.Input == HTTPRequest {

        private let loader: Wrapped
        private let generateIdentifier: (HTTPRequest) -> String

        init(loader: Wrapped,
             generateIdentifier: @escaping (HTTPRequest) -> String = generateUUID) {
            self.loader = loader
            self.generateIdentifier = generateIdentifier
        }

        public func load(_ request: HTTPRequest) async throws -> Wrapped.Output {
            var modifiedRequest = request
            modifiedRequest.identity = HTTPRequestIdentifier(id: generateIdentifier(request))
            return try await loader.load(modifiedRequest)
        }
    }
}

extension Loaders.ApplyRequestIdentity: HTTPLoader where Output == HTTPResponse {}
