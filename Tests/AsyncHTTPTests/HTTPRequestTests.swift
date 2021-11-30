import XCTest
import AsyncHTTP

class HTTPRequestTests: XCTestCase {
    func test_whenRequestIsCreated_thenHasDefaultGETMethod() async throws {
        // Given


        // When
        let request = HTTPRequest(url: URL(string: "dummy")!)

        // Then
        XCTAssertEqual(request?.method, .get)
    }

    func test_whenRequestIsCreated_thenHasURL() async throws {
        // Given


        // When
        let request = HTTPRequest(url: URL(string: "https://example.com")!)

        // Then
        XCTAssertEqual(request?.url, URL(string: "https://example.com"))
    }
}
