import Foundation

extension HTTPRequest: Formattible {}

extension HTTPRequest: DefaultFormattible {
    public static var defaultFormatter = StandardHTTPRequestFormatter()
}

public extension Formatter where Self == CURLHTTPRequestFormatter {
    static var curl: CURLHTTPRequestFormatter {
        CURLHTTPRequestFormatter()
    }
}

public extension Formatter where Self == CURLHTTPRequestFormatter {
    static var http: StandardHTTPRequestFormatter {
        StandardHTTPRequestFormatter()
    }
}

public class CURLHTTPRequestFormatter: Formatter {
    public typealias RawValue = HTTPRequest

    public init() {}

    public func format(_ request: HTTPRequest) -> String {
        guard let url = request.url else { return "" }
        var result: String = "curl"
        result += " --request \(request.method.httpFormatted())"
        for (key, value) in request.headers.sorted(by: \.key.name) {
            let header = "\(key.httpFormatted()): \(value.httpFormatted())"
            result += " --header \(header.quoted())"
        }
        let body = request.body.httpFormatted()
        if !body.isEmpty {
            result += " --data \(body.quoted())"
        }
        result += " \(url.httpFormatted().quoted())"
        return result
    }
}

public class StandardHTTPRequestFormatter: Formatter {
    public typealias RawValue = HTTPRequest

    public init() {}

    public func format(_ request: HTTPRequest) -> String {
        guard let url = request.url else { return "" }
        var result = "\(request.method.httpFormatted()) \(url.httpFormatted()) \(request.version.httpFormatted())\n"
        for (key, value) in request.headers.sorted(by: \.key.name) {
            result += "\(key.httpFormatted()): \(value.httpFormatted())\n"
        }
        result += "\n\(request.body.httpFormatted())"
        return result
    }
}

private extension String {
    func quoted(using character: Character = #"""#) -> String {
        "\(character)\(escaping(character: character))\(character)"
    }

    func escaping(character: Character) -> String {
        replacingOccurrences(of: String(character), with: "\\\(character)")
    }
}
