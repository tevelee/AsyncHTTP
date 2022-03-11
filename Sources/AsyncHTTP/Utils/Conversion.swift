import Foundation

public protocol ConversionStrategy {
    associatedtype RawValue
    associatedtype ConvertedValue
}

public protocol DecoderStrategy: ConversionStrategy {
    static func decode(_ value: RawValue) -> ConvertedValue
}

public protocol EncoderStrategy: ConversionStrategy {
    static func encode(_ value: ConvertedValue) -> RawValue
}

public typealias TwoWayConversionStrategy = EncoderStrategy & DecoderStrategy

@propertyWrapper
public struct Converted<Converter: ConversionStrategy> {
    public var wrappedValue: Converter.ConvertedValue

    public init(wrappedValue: Converter.ConvertedValue) {
        self.wrappedValue = wrappedValue
    }
}

extension Converted: Equatable where Converter.ConvertedValue: Equatable {}
extension Converted: Hashable where Converter.ConvertedValue: Hashable {}

extension Converted: Decodable where Converter.RawValue: Decodable, Converter: DecoderStrategy {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Converter.RawValue.self)
        let decodedValue = Converter.decode(rawValue)
        self.init(wrappedValue: decodedValue)
    }
}

extension Converted: Encodable where Converter.RawValue: Encodable, Converter: EncoderStrategy {
    public func encode(to encoder: Encoder) throws {
        let rawValue = Converter.encode(wrappedValue)
        try rawValue.encode(to: encoder)
    }
}

extension Optional: ConversionStrategy where Wrapped: ConversionStrategy {
    public typealias RawValue = Wrapped.RawValue?
    public typealias ConvertedValue = Wrapped.ConvertedValue?
}

extension Optional: EncoderStrategy where Wrapped: EncoderStrategy {
    public static func encode(_ value: Wrapped.ConvertedValue?) -> Wrapped.RawValue? {
        value.map(Wrapped.encode)
    }
}

extension Optional: DecoderStrategy where Wrapped: DecoderStrategy {
    public static func decode(_ value: Wrapped.RawValue?) -> Wrapped.ConvertedValue? {
        value.map(Wrapped.decode)
    }
}

extension Converted: ExpressibleByNilLiteral where Converter.ConvertedValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.init(wrappedValue: nil)
    }
}

public extension KeyedDecodingContainer {
    func decode<Converter: DecoderStrategy>(_ type: Converted<Converter?>.Type, forKey key: Key) throws -> Converted<Converter?> where Converter.RawValue: Decodable {
        try decodeIfPresent(type, forKey: key) ?? Converted(wrappedValue: nil)
    }
}

public extension KeyedEncodingContainer {
    mutating func encode<Converter: EncoderStrategy>(_ value: Converted<Converter?>, forKey key: Key) throws where Converter.RawValue: Encodable {
        if let wrappedValue = value.wrappedValue {
            try encode(Converter.encode(wrappedValue), forKey: key)
        }
    }
}
