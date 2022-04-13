import Foundation

#if !canImport(Combine)
public protocol TopLevelDecoder {
    associatedtype Input

    func decode<T: Decodable>(_ type: T.Type, from: Input) throws -> T
}

extension JSONDecoder: TopLevelDecoder {
    public typealias Input = Data
}

public protocol TopLevelEncoder {
    associatedtype Output

    func encode<T: Encodable>(_ value: T) throws -> Output
}

extension JSONEncoder: TopLevelEncoder {
    public typealias Output = Data
}
#endif
