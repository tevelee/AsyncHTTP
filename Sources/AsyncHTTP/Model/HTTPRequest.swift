import Foundation

public struct HTTPRequest: Equatable, Hashable, Sendable {
    public var method: HTTPMethod
    public var body: HTTPRequestBody {
        didSet {
            headers.merge(body.additionalHeaders) { old, _ in old }
        }
    }
    public var version: HTTPVersion
    public var headers: [HTTPHeader<String>: String] {
        get {
            let headers = serverEnvironment.map { $0.apply(to: rawHeaders) } ?? rawHeaders
            return headers
        }
        set {
            rawHeaders = newValue
        }
    }
    public var url: URL? {
        let components = serverEnvironment.map { $0.apply(to: urlComponents) } ?? urlComponents
        return components.url
    }

    private var options: [ObjectIdentifier: AnyHashable] = [:]
    private var urlComponents = URLComponents()
    private var rawHeaders: [HTTPHeader<String>: String]

    public init(method: HTTPMethod = .get,
                headers: [HTTPHeader<String>: String] = [:],
                version: HTTPVersion = .default,
                body: HTTPRequestBody = .empty) {
        self.method = method
        self.rawHeaders = headers
        self.urlComponents = URLComponents()
        self.body = body
        self.version = version

        scheme = .https
    }

    public init?(method: HTTPMethod = .get,
                 url: URL,
                 headers: [HTTPHeader<String>: String] = [:],
                 version: HTTPVersion = .default,
                 body: HTTPRequestBody = .empty) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        self.method = method
        self.rawHeaders = headers
        self.body = body
        self.version = version
        self.urlComponents = components
    }

    internal var urlRequest: URLRequest? {
        guard let url = url else {
            return nil
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.httpFormatted()
        urlRequest.httpBody = body.content
        for (key, value) in headers {
            urlRequest.addValue(value, forHTTPHeaderField: key.name)
        }
        return urlRequest
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

    public var cookies: [(name: String, value: String)]? {
        headers[HTTPHeader.cookie].map { cookiesHeader in
            cookiesHeader.components(separatedBy: "; ").map { cookieEntry in
                let segments = cookieEntry.split(separator: "=").map(String.init)
                return (segments[0], segments[1])
            }
        }
    }

    public mutating func set(cookies: [HTTPCookie]) {
        let newHeaders = HTTPCookie.requestHeaderFields(with: cookies).mapKeys(HTTPHeader<String>.init(name:))
        headers.merge(newHeaders) { _, new in new }
    }

    public mutating func add(cookie: HTTPCookie) {
        addCookie(name: cookie.name, value: cookie.value)
    }

    public mutating func addCookie(name: String, value: String) {
        var modifiedCookies = cookies ?? []
        if let existing = modifiedCookies.firstIndex(where: { $0.name == name }) {
            modifiedCookies.remove(at: existing)
        }
        modifiedCookies.append((name, value))
        headers[HTTPHeader.cookie] = modifiedCookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
    }
}

extension Dictionary {
    func mapKeys<NewKey: Hashable>(_ block: (Key) -> NewKey) -> [NewKey: Value] {
        Dictionary<NewKey, [(key: Key, value: Value)]>(grouping: self) { key, _ in block(key) }.compactMapValues(\.first?.value)
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
