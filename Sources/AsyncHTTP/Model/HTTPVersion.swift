import Foundation

public struct HTTPVersion: Equatable, Hashable, Codable, Sendable {
    internal let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(version: Double) {
        rawValue = NumberFormatter.httpVersion.string(from: NSNumber(value: version)) ?? String(version)
    }
}

private extension NumberFormatter {
    private func configured(with block: (inout NumberFormatter) -> Void) -> NumberFormatter {
        var copy = self
        block(&copy)
        return copy
    }

    static let httpVersion = NumberFormatter().configured {
        $0.locale = Locale(identifier: "en_US_POSIX")
        $0.allowsFloats = false
        $0.alwaysShowsDecimalSeparator = true
        $0.minimumFractionDigits = 1
        $0.maximumFractionDigits = 1
        $0.minimumIntegerDigits = 1
        $0.maximumIntegerDigits = 1
    }
}

extension HTTPVersion: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.init(version: value)
    }
}

extension HTTPVersion {
    public static let v0_9: Self = 0.9
    public static let v1_0: Self = 1.0
    public static let v1_1: Self = 1.1
    public static let v2_0: Self = 2.0
    public static let v3_0: Self = 3.0

    public static let `default`: Self = v2_0
}
