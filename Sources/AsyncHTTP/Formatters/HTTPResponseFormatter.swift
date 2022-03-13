import Foundation

extension HTTPResponse: Formattible {}

extension HTTPResponse: DefaultFormattible {
    public static var defaultFormatter = StandardHTTPResponseFormatter()
}

public extension Formatter where Self == StandardHTTPResponseFormatter {
    static var http: StandardHTTPResponseFormatter {
        StandardHTTPResponseFormatter()
    }
}

public class StandardHTTPResponseFormatter: Formatter {
    public typealias RawValue = HTTPResponse

    public init() {}

    public func format(_ response: HTTPResponse) -> String {
        var result = "\(response.request.version.httpFormatted()) \(response.status.code) \(response.status.message)\n"
        for (key, value) in response.headers.sorted(by: \.key.name) {
            result += "\(key.httpFormatted()): \(value.httpFormatted())\n"
        }
        result += "\n"
        if let stringBody = String(data: response.body, encoding: .utf8) {
            result += stringBody
        }
        return result
    }
}
