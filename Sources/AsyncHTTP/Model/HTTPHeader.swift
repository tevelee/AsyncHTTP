import Foundation

public struct HTTPHeader<Value: HTTPFormattible>: Equatable, Hashable, Codable, Sendable {
    public let name: String

    public init(name: String) {
        self.name = name.capitalized
    }

    public var formatted: HTTPHeader<String> {
        .init(name: name)
    }
}

extension HTTPHeader: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(name: value)
    }
}

public extension HTTPHeader where Value == MIMEType {
    static let accept: Self = "Accept"
    static let contentType: Self = "Content-Type"
    static let contentDisposition: Self = "Content-Disposition"
}

extension HTTPHeader where Value == AuthorizationHeader {
    public static let authorization: Self = "Authorization"
}

public extension HTTPHeader where Value == String {
    static let userAgent: Self = "User-Agent"
    static let location: Self = "Location"
    static let host: Self = "Host"
    static let acceptEncoding: Self = "Accept-Encoding"
    static let acceptCharset: Self = "Accept-Charset"
    static let connection: Self = "Connection"
    static let contentEncoding: Self = "Content-Encoding"
    static let contentLocation: Self = "Content-Location"
    static let contentTransferEncoding: Self = "Content-Transfer-Encoding"
    static let cookie: Self = "Cookie"
    static let setCookie: Self = "Set-Cookie"
}

public extension HTTPHeader where Value == Locale {
    static let acceptLanguage: Self = "Accept-Language"
    static let contentLanguage: Self = "Content-Language"
}

extension DateFormatter {
    private func configured(with block: (inout DateFormatter) -> Void) -> DateFormatter {
        var copy = self
        block(&copy)
        return copy
    }

    public static let http = DateFormatter().configured {
        $0.locale = Locale(identifier: "en_US_POSIX")
        $0.calendar = Calendar(identifier: .gregorian)
        $0.timeZone = TimeZone(secondsFromGMT: 0)
        $0.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
    }
}

extension Date: Formattible {}

extension Formatter where Self == DateFormatter {
    public static var http: DateFormatter {
        DateFormatter.http
    }
}

extension DateFormatter: Formatter {
    public typealias RawValue = Date

    public func format(_ date: Date) -> String {
        string(from: date)
    }
}

public extension HTTPHeader where Value == Date {
    static let ifModifiedSince = "If-Modified-Since"
    static let date = "Date"
}

public extension HTTPHeader where Value == HTTPMethod {
    static let allow: Self = "Allow"
}

public extension HTTPHeader where Value == Int {
    static let contentLength: Self = "Content-Length"
}

public struct AuthorizationHeader: HTTPFormattible {
    public struct `Type`: RawRepresentable, ExpressibleByStringLiteral {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.init(rawValue: value)
        }
    }

    public let type: `Type`?
    public let credentials: String

    public func httpFormatted() -> String {
        guard let type = type else {
            return credentials
        }
        return "\(type.rawValue) \(credentials)"
    }

    init(type: `Type`? = nil, credentials: String) {
        self.type = type
        self.credentials = credentials
    }

    public static func basic(_ credentials: String) -> AuthorizationHeader {
        AuthorizationHeader(type: .basic, credentials: credentials)
    }

    public static func bearer(token: String) -> AuthorizationHeader {
        AuthorizationHeader(type: .bearer, credentials: token)
    }
}

public extension AuthorizationHeader.`Type` {
    static let basic: Self = "Basic"
    static let bearer: Self = "Bearer"
    static let digest: Self = "Digest"
    static let oauth: Self = "OAuth"
}
