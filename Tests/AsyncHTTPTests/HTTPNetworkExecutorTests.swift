import XCTest
import AsyncHTTP

final class HTTPNetworkExecutorTests: XCTestCase {
    let testLoader = AnyLoader { _ in (Data(), .dummy()) }.http

    func test_whenLoadingURLSessionLoader_thenCallsURLSessionDataTask() async throws {
        // Given
        let request = HTTPRequest(url: URL(string: "https://google.com")!)!

        // When
        let response = try await testLoader.load(request)

        // Then
        XCTAssertEqual(response.request, request)
    }

    func test_whenLoadingUsingServerEnvironment_thenAppliesProperties() async throws {
        // Given
        let request = try HTTPRequest().configured {
            $0.path = "endpoint"
            $0.body = try .json(["a": "b"])
            $0[header: .accept] = .application.json.appending(.characterSet, value: .utf8)
            $0[header: .authorization] = .bearer(token: "token")
            $0.addQueryParameter(name: "q", value: "search")
            $0.addQueryParameter(name: "sid", value: "1")
            $0.serverEnvironment = .production
            $0.timeout = 1
            $0.retryStrategy = .immediately(maximumNumberOfAttempts: 5)
        }
        var loadedRequest: HTTPRequest?
        let loader: some HTTPLoader = testLoader
            .capture { loadedRequest = $0 }
            .applyServerEnvironment()
            .applyTimeout()
            .flatMap { $0.response.statusCode.in(200 ..< 300) ? .success($0) : .failure("not 2XX response code") }
            .intercept { $0.headers["X-Header"] = "value" }
//            .delay(seconds: 10)
            .deduplicate()
            .throttle(maximumNumberOfRequests: 1)

        // When
        _ = try await loader.load(request)

        // Then
        XCTAssertEqual(loadedRequest?.url?.absoluteString, "https://prod.example.com/v1/endpoint?q=search&sid=1")
        XCTAssertEqual(loadedRequest?.headers["Accept"], "application/json; charset=\"utf-8\"")
        XCTAssertEqual(loadedRequest?.headers["Authorization"], "Bearer token")
        XCTAssertEqual(loadedRequest?.headers["X-API-KEY"], "test")
        XCTAssertEqual(loadedRequest?.headers["X-Header"], "value")
        XCTAssertEqual(loadedRequest?.body.content, "{\"a\":\"b\"}".data(using: .utf8))
    }

    func test_whenDecoding_thenItSucceeds() async throws {
        // Given
        struct CustomResponse: Decodable, Equatable {
            let key: String
        }
        let httpLoader: some HTTPLoader = AnyLoader { _ in (Data(#"{"key": "value"}"#.utf8), .dummy()) }.http
        let loader: AnyLoader<HTTPRequest, CustomResponse> = httpLoader
            .map(\.body)
            .decode(using: JSONDecoder(), to: CustomResponse.self)
            .eraseToAnyLoader()

        // When
        let output = try await loader.load(HTTPRequest())

        // Then
        XCTAssertEqual(output, CustomResponse(key: "value"))
    }
}

private extension ServerEnvironment {
    static let production = Self(host: "prod.example.com", pathPrefix: "v1", headers: ["X-API-KEY": "test"])
}

private extension URLResponse {
    static func dummy(url: URL = URL(string: "test")!, statusCode: Int = 200) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}

extension String: Error {}

private extension Int {
    func `in`(_ range: Range<Int>) -> Bool {
        range.contains(self)
    }
}
