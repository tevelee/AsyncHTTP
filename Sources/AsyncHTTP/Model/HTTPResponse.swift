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

    public var status: HTTPStatus {
        HTTPStatus(code: response.statusCode)
    }

    public var url: URL? {
        response.url
    }

    public var headers: [HTTPHeader<String>: String] {
        response.allHeaderFields.mapKeys { HTTPHeader<String>(name: $0.description) }.compactMapValues { $0 as? String }
    }

    public subscript(header header: HTTPHeader<String>) -> String? {
        response.value(forHTTPHeaderField: header.name)
    }

    public var cookies: [HTTPCookie]? {
        let headers = self.headers.mapKeys(\.name)
        guard let url = url, !headers.isEmpty else {
            return nil
        }
        return HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
    }
}

extension HTTPResponse: Identifiable {
    public var id: HTTPRequest.ID {
        request.id
    }
}
