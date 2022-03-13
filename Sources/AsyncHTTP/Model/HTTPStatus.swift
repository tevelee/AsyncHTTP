import Foundation

public struct HTTPStatus: Equatable, Hashable, Codable {
    public let code: Int

    public init(code: Int) {
        self.code = code
    }

    public var message: String {
        switch code {
            case 200:
                return "OK"
            case let value:
                return HTTPURLResponse.localizedString(forStatusCode: value).capitalized
        }
    }
}

extension HTTPStatus: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(code: value)
    }
}

extension HTTPStatus {
    public static let ok: Self = 200
    public static let created: Self = 201
    public static let notModified: Self = 304
    public static let badRequest: Self = 400
    public static let unauthorized: Self = 401
    public static let forbidden: Self = 403
    public static let notFound: Self = 404
    public static let internalServerError: Self = 500
    public static let serviceUnavailable: Self = 503
}
