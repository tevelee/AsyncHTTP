import Combine
import Foundation

public struct HTTPResponse {
    public let request: HTTPRequest
    public let response: HTTPURLResponse
    public let body: Data

    public func decodedBody<T: Decodable, Decoder: TopLevelDecoder>(using decoder: Decoder, type: T.Type = T.self) throws -> T where Decoder.Input == Data {
        try decoder.decode(type, from: body)
    }

    public func jsonBody<T: Decodable>(using decoder: JSONDecoder = JSONDecoder(), type: T.Type = T.self) throws -> T {
        try decodedBody(using: decoder)
    }
}
