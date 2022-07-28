import AsyncHTTP
import Foundation
import XCTest

final class ConvertedTests: XCTestCase {
    func test_whenDecodingConvertedProperty_thenDecodesCorrectly() throws {
        // Given
        struct Response: Decodable {
            @Converted<ISO8601> var date: Date
        }

        // When
        let decoded = try JSONDecoder().decode(Response.self, from: #"""
        {
          "date": "1970-01-01T00:00:00Z"
        }
        """#.data)

        // Then
        XCTAssertEqual(decoded.date, Date(timeIntervalSince1970: 0))
    }

    func test_whenDecodingOptionalConvertedProperty_thenDecodesCorrectly() throws {
        // Given
        struct Response: Decodable {
            @Converted<ISO8601?> var date: Date?
        }

        // When
        let decoded = try JSONDecoder().decode(Response.self, from: "{}".data)

        // Then
        XCTAssertNil(decoded.date)
    }

    func test_whenEncodingConvertedProperty_thenEncodesCorrectly() throws {
        // Given
        struct Request: Encodable {
            @Converted<ISO8601> var date: Date
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting.formUnion(.prettyPrinted)

        // When
        let encoded = try encoder.encode(Request(date: Date(timeIntervalSince1970: 0)))

        // Then
        XCTAssertEqual(encoded.string, #"""
        {
          "date" : "1970-01-01T00:00:00Z"
        }
        """#)
    }

    func test_whenEncodingOptionalConvertedProperty_thenEncodesCorrectly() throws {
        // Given
        struct Request: Encodable {
            @Converted<ISO8601?> var date: Date?
        }

        // When
        let encoded = try JSONEncoder().encode(Request())

        // Then
        XCTAssertEqual(encoded.string, "{}")
    }

    func test_whenDecodingConvertedPropertyWithComposition_thenDecodesCorrectly() throws {
        // Given
        struct Response: Decodable {
            @Converted<Composed<ISO8601, Day>> var day: Int
        }

        // When
        let decoded = try JSONDecoder().decode(Response.self, from: #"""
        {
          "day": "1970-01-13T00:00:00Z"
        }
        """#.data)

        // Then
        XCTAssertEqual(decoded.day, 13)
    }
}

extension String {
    var data: Data {
        Data(utf8)
    }
}

extension Data {
    var string: String? {
        String(data: self, encoding: .utf8)
    }
}

private struct ISO8601: TwoWayConversionStrategy {
    typealias RawValue = String
    typealias ConvertedValue = Date

    static let formatter = ISO8601DateFormatter()

    static func encode(_ value: Date) -> String {
        formatter.string(from: value)
    }

    static func decode(_ value: String) throws -> Date {
        guard let date = formatter.date(from: value) else {
            throw ConversionError()
        }
        return date
    }

    struct ConversionError: Error {}
}

private struct Day: DecoderStrategy {
    typealias RawValue = Date
    typealias ConvertedValue = Int

    static func decode(_ value: Date) throws -> Int {
        Calendar(identifier: .gregorian).dateComponents([.day], from: value).day!
    }
}
