import AsyncHTTP
import XCTest

final class HTTPFormatterTests: XCTestCase {
    func test_whenFormattingRequestWithCURL_thenOutputsTheCorrectFormat() throws {
        // Given
        let request = try HTTPRequest(url: URL(string: "https://google.com")!)!.configured { request in
            request[header: .userAgent] = "Safari"
            request.body = try .json(["a": "b", "c": 1])
        }

        // When
        let output = request.formatted(using: .curl)

        // Then
        XCTAssertEqual(output, #"curl --request GET --header "Content-Type: application/json; charset=\"utf-8\"" --header "User-Agent: Safari" --data "{"a":"b","c":1}" https://google.com"#)
    }

    func test_whenFormattingRequestWithStandardHTTPFormat_thenOutputsTheCorrectFormat() throws {
        // Given
        let request = try HTTPRequest(url: URL(string: "https://google.com")!)!.configured { request in
            request[header: .userAgent] = "Safari"
            request.body = try .json(["a": "b", "c": 1])
        }

        // When
        let output = request.formatted(using: .http)

        // Then
        XCTAssertEqual(output, #"""
        GET https://google.com HTTP/2.0
        Content-Type: application/json; charset="utf-8"
        User-Agent: Safari

        {"a":"b","c":1}
        """#)
    }

    func test_whenFormattingResponseWithStandardHTTPFormat_thenOutputsTheCorrectFormat() async throws {
        // Given
        let urlResponse = HTTPURLResponse(url: URL(string: "https://google.com")!,
                                          statusCode: 404,
                                          httpVersion: nil,
                                          headerFields: ["Content-Type": "application/json"])!
        let testLoader = AnyLoader { _ in (#"{"a": "b", "c": null, "d": 1, "e": [true, false]}"#.data, urlResponse) }.httpLoader()
        let response = try await testLoader.load(HTTPRequest())

        // When
        let output = response.formatted()

        // Then
        XCTAssertEqual(output, #"""
        HTTP/2.0 404 Not Found
        Content-Type: application/json

        {"a": "b", "c": null, "d": 1, "e": [true, false]}
        """#)
    }
}
