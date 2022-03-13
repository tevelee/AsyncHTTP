import Foundation

public struct HTTPMethod: Equatable, Hashable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension HTTPMethod: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension HTTPMethod {
    public static let connect: Self = "CONNECT"
    public static let delete: Self = "DELETE"
    public static let get: Self = "GET"
    public static let head: Self = "HEAD"
    public static let options: Self = "OPTIONS"
    public static let post: Self = "POST"
    public static let put: Self = "PUT"
    public static let patch: Self = "PATCH"
    public static let trace: Self = "TRACE"
}
