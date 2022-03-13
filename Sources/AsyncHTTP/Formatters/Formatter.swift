import Foundation

public protocol Formatter: ConversionStrategy where ConvertedValue == String {
    func format(_ value: RawValue) -> String
}

public protocol Formattible {}

public extension Formattible {
    func formatted<F: Formatter>(using formatter: F) -> String where F.RawValue == Self {
        formatter.format(self)
    }
}

public protocol DefaultFormattible where DefaultFormatter.RawValue == Self {
    associatedtype DefaultFormatter: Formatter
    static var defaultFormatter: DefaultFormatter { get }
}

public extension Formattible where Self: DefaultFormattible {
    func formatted() -> String {
        formatted(using: Self.defaultFormatter)
    }
}
