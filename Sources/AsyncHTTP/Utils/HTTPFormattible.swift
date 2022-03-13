import Foundation

public protocol HTTPFormattible {
    func httpFormatted() -> String
}

extension String: HTTPFormattible {
    public func httpFormatted() -> String {
        self
    }
}

extension URL: HTTPFormattible {
    public func httpFormatted() -> String {
        absoluteString
    }
}

extension Date: HTTPFormattible {
    public func httpFormatted() -> String {
        formatted(using: .http)
    }
}

extension HTTPRequestBody: HTTPFormattible {
    public func httpFormatted() -> String {
        String(data: content, encoding: .utf8) ?? ""
    }
}

extension Locale: HTTPFormattible {
    public func httpFormatted() -> String {
        identifier
    }
}

extension Int: HTTPFormattible {
    public func httpFormatted() -> String {
        String(self)
    }
}

extension HTTPHeader: HTTPFormattible {
    public func httpFormatted() -> String {
        name
    }
}

extension HTTPMethod: HTTPFormattible {
    public func httpFormatted() -> String {
        rawValue.uppercased()
    }
}

extension HTTPVersion: HTTPFormattible {
    public func httpFormatted() -> String {
        "HTTP/\(rawValue)"
    }
}

extension MIMEType: HTTPFormattible {
    public func httpFormatted() -> String {
        rawValue
    }
}

extension HTTPRequest: HTTPFormattible {
    public func httpFormatted() -> String {
        formatted()
    }
}

extension HTTPResponse: HTTPFormattible {
    public func httpFormatted() -> String {
        formatted()
    }
}
