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

extension Loader where Input == HTTPRequest {
#if compiler(>=5.7)
    @_disfavoredOverload
    public func identifyRequests(generateIdentifier: @escaping (HTTPRequest) -> String = { _ in UUID().uuidString }) -> some Loader<HTTPRequest, Output> {
        Loaders.ApplyRequestIdentity(loader: self, generateIdentifier: generateIdentifier)
    }
#endif

    public func identifyRequests(generateIdentifier: @escaping (HTTPRequest) -> String = { _ in UUID().uuidString }) -> Loaders.ApplyRequestIdentity<Self> {
        .init(loader: self, generateIdentifier: generateIdentifier)
    }
}


extension Loaders {
    public struct ApplyRequestIdentity<Wrapped: Loader>: CompositeLoader where Wrapped.Input == HTTPRequest {
        private let loader: Wrapped
        private let generateIdentifier: (HTTPRequest) -> String

        init(loader: Wrapped,
             generateIdentifier: @escaping (HTTPRequest) -> String = { _ in UUID().uuidString }) {
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
