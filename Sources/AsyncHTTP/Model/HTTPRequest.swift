import Foundation

public struct HTTPRequest: Equatable, Hashable, Sendable {
    public var method: HTTPMethod
    public var headers: [HTTPHeader<String>: String]
    public var body: HTTPBody
    public var version: HTTPVersion
    public var url: URL? { urlComponents.url }
    private var options: [ObjectIdentifier: AnyHashable] = [:]
    private var urlComponents = URLComponents()

    public init(method: HTTPMethod = .get,
                headers: [HTTPHeader<String>: String] = [:],
                version: HTTPVersion = .default,
                body: HTTPBody = .empty) {
        self.method = method
        self.headers = headers
        self.urlComponents = URLComponents()
        self.body = body
        self.version = version

        scheme = .https
    }

    public init?(method: HTTPMethod = .get,
                 url: URL,
                 headers: [HTTPHeader<String>: String] = [:],
                 version: HTTPVersion = .default,
                 body: HTTPBody = .empty) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        self.method = method
        self.headers = headers
        self.body = body
        self.version = version
        self.urlComponents = components
    }

    internal var urlRequest: URLRequest? {
        guard let url = url else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.standardFormat
        return request
    }

    public subscript<O: HTTPRequestOption>(option type: O.Type) -> O.Value {
        get {
            let id = ObjectIdentifier(type)
            guard let value = options[id]?.base as? O.Value else {
                return type.defaultValue
            }
            return value
        }
        set {
            let id = ObjectIdentifier(type)
            options[id] = AnyHashable(newValue)
        }
    }
}

extension HTTPRequest {
    public var scheme: URIScheme {
        get { urlComponents.scheme.map(URIScheme.init(rawValue:)) ?? .https }
        set { urlComponents.scheme = newValue.rawValue }
    }

    public var host: String? {
        get { urlComponents.host }
        set { urlComponents.host = newValue }
    }

    public var path: String {
        get { urlComponents.path }
        set { urlComponents.path = newValue }
    }

    public var query: [URLQueryItem]? {
        get { urlComponents.queryItems }
        set { urlComponents.queryItems = newValue }
    }

    public var port: Int? {
        get { urlComponents.port }
        set { urlComponents.port = newValue }
    }

    public mutating func addQueryParameter(name: String, value: String) {
        let item = URLQueryItem(name: name, value: value)
        add(queryItem: item)
    }

    public mutating func add(queryItem item: URLQueryItem) {
        if query != nil {
            query?.append(item)
        } else {
            query = [item]
        }
    }

    public subscript<Value>(header header: HTTPHeader<Value>) -> Value? {
        get { headers[header.formatted] as? Value }
        set { headers[header.formatted] = newValue?.httpFormatted() }
    }
}

public protocol HTTPRequestOption {
    associatedtype Value: Hashable

    static var defaultValue: Value { get }
}

extension HTTPRequest {
    public func configured(with block: (inout Self) throws -> Void) rethrows -> Self {
        var copy = self
        try block(&copy)
        return copy
    }

    public func configured(with block: (inout Self) -> Void) -> Self {
        var copy = self
        block(&copy)
        return copy
    }
}

extension URLComponents: @unchecked Sendable {}
extension AnyHashable: @unchecked Sendable {}
