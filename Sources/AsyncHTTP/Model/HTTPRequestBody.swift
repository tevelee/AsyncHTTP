import Combine
import Foundation

public struct HTTPRequestBody: Equatable, Hashable, Sendable {
    public var content: Data
    public var additionalHeaders: [HTTPHeader<String>: String]

    public init(content: Data, additionalHeaders: [HTTPHeader<String>: String] = [:]) {
        self.content = content
        self.additionalHeaders = additionalHeaders
    }

    public init<Value>(content: Data, header name: HTTPHeader<Value>, _ value: Value) {
        self.additionalHeaders = [:]
        self.content = content
        self[header: name] = value
    }

    public subscript<Value>(header header: HTTPHeader<Value>) -> Value? {
        get { additionalHeaders[header.formatted] as? Value }
        set { additionalHeaders[header.formatted] = newValue?.httpFormatted() }
    }
}

extension HTTPRequestBody: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .text(value)
    }

    public static let empty = HTTPRequestBody(content: Data())

    public static func string(_ content: String, contentType: MIMEType = .text.plain) -> HTTPRequestBody {
        .data(content.data(using: .utf8) ?? Data(), contentType: contentType)
    }

    public static func data(_ content: Data, contentType: MIMEType) -> HTTPRequestBody {
        HTTPRequestBody(content: content, header: .contentType, contentType)
    }

    public static func text(_ content: String) -> HTTPRequestBody {
        .string(content, contentType: .text.plain)
    }

    public static func form(values: [URLQueryItem]) -> HTTPRequestBody {
        let content = values.compactMap { item in
            guard let name = item.name.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
                  let value = item.value?.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else {
                      return nil
                  }
            return "\(name)=\(value)"
        }.joined(separator: "&")
        return .string(content, contentType: .application.wwwForm.appending(.characterSet, value: .utf8))
    }

    public static func form(values: [String: String]) -> HTTPRequestBody {
        .form(values: values.map { URLQueryItem(name: $0.key, value: $0.value) })
    }

    public static func json<T: Encodable>(_ object: T, encoder: JSONEncoder = JSONEncoder()) throws -> HTTPRequestBody {
        let content = try encoder.encode(object)
        return .data(content, contentType: .application.json.appending(.characterSet, value: .utf8))
    }

    public static func json(_ object: Any, options: JSONSerialization.WritingOptions = [.sortedKeys]) throws -> HTTPRequestBody {
        let content = try JSONSerialization.data(withJSONObject: object, options: options)
        return .data(content, contentType: .application.json.appending(.characterSet, value: .utf8))
    }

    public static func data<T: Encodable, Encoder: TopLevelEncoder>(_ object: T, encoder: Encoder) throws -> HTTPRequestBody where Encoder.Output == Data {
        .init(content: try encoder.encode(object))
    }

    public static func multipart(boundary: String = UUID().uuidString, parts: [Part]) -> HTTPRequestBody {
        var data = Data()
        for part in parts {
            data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            for header in part.body.additionalHeaders {
                data.append("\(header.key.name):\(header.value)\r\n".data(using: .utf8)!)
            }
            data.append("\r\n".data(using: .utf8)!)
            data.append(part.body.content)
        }
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        return .data(data, contentType: .multipart.appending(.boundary, value: boundary))
    }

    public struct Part {
        private let name: String
        private let fileName: String?
        private let content: HTTPRequestBody

        public init(name: String, fileName: String? = nil, content: HTTPRequestBody) {
            self.name = name
            self.fileName = fileName
            self.content = content
        }

        public var body: HTTPRequestBody {
            var mimeType: MIMEType = .formData.appending(.name, value: name)
            if let fileName = fileName {
                mimeType.append(.fileName, value: fileName)
            }
            var body = content
            body[header: .contentDisposition] = mimeType
            return body
        }
    }
}

extension Data: @unchecked Sendable {}
