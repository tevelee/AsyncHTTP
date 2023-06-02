@testable import AsyncHTTP
import XCTest

final class HTTPNetworkExecutorTests: XCTestCase {
    private let testLoader = StaticLoader(data: Data(), response: .dummy())

    func test_whenLoadingURLSessionLoader_thenCallsURLSessionDataTask() {
        // Given
        let request = HTTPRequest(url: URL(string: "https://google.com")!)!

        // When
        let response = testLoader.load(request)

        // Then
        XCTAssertEqual(response.request, request)
    }

    func test_whenLoadingUsingServerEnvironment_thenAppliesProperties() async throws {
        struct InvalidResponseError: Error {
            let statusCode: Int
        }
        // Given
        let request = try HTTPRequest().configured {
            $0.serverEnvironment = .production
            $0.path = "endpoint"
            $0.method = .post
            $0.body = try .json(["a": "b"])
            $0[header: .accept] = .application.json.appending(.characterSet, value: .utf8)
            $0[header: .authorization] = .bearer(token: "token")
            $0.add(cookie: .test2)
            $0.add(cookie: .test1)
            $0.addQueryParameter(name: "q", value: "search")
            $0.addQueryParameter(name: "sid", value: "1")
            $0.timeout = 1
            $0.retryStrategy = .immediately(maximumNumberOfAttempts: 5).filter { error in
                if let error = error as? InvalidResponseError {
                    return (500..<600).contains(error.statusCode)
                }
                return true
            }
        }
        var loadedRequest: HTTPRequest?
        let loader = StaticLoader(
            (data: Data(), response: .dummy(statusCode: 503)),
            (data: Data(), response: .dummy(statusCode: 200))
        )
        .capture { loadedRequest = $0 }
        .networkConstrained()
        .applyServerEnvironment()
        .applyTimeout(default: 60)
        .map { response in
            guard (200 ..< 300).contains(response.status.code) else {
                throw InvalidResponseError(statusCode: response.status.code)
            }
            return response
        }
        .applyRetryStrategy()
        .intercept { $0.headers["X-Header"] = "value" }
//        .delay(seconds: 0)
        .deduplicate()
        .throttle(maximumNumberOfRequests: 1)
        .identifyRequests()
        .validateRequests()

        // When
        let response = try await loader.load(request)

        // Then
        XCTAssertEqual(request.url?.absoluteString, "https://prod.example.com/v1/endpoint?q=search&sid=1")
        XCTAssertEqual(request.method, "POST")
        XCTAssertEqual(request[header: "Accept"], "application/json; charset=\"utf-8\"")
        XCTAssertEqual(request[header: "Authorization"], "Bearer token")
        XCTAssertEqual(request[header: "X-API-KEY"], "test")
        XCTAssertEqual(loadedRequest?[header: "X-Header"], "value")
        XCTAssertEqual(request[header: "Cookie"], "test2=2; test1=1")
        XCTAssertEqual(request.body.content, Data(#"{"a":"b"}"#.utf8))
        XCTAssertNotNil(loadedRequest?.id)
        XCTAssertEqual(loadedRequest?.id, response.id)
    }

    func test_whenDecodingResponse_thenItSucceeds() throws {
        // Given
        struct CustomResponse: Decodable, Equatable {
            let key: String
        }
        let loader = StaticLoader(data: Data(#"{"key": "value"}"#.utf8), response: .dummy(headers: [
            "User-Agent": "X",
            "Set-Cookie": "a=b; Domain=google.com; Path=/; Secure; HttpOnly"
        ]))

        // When
        let response = loader.load(HTTPRequest())

        // Then
        XCTAssertEqual(try response.jsonBody(), CustomResponse(key: "value"))
        XCTAssertEqual(response.cookies?.first?.value, "b")
        XCTAssertEqual(response[header: .userAgent], "X")
    }

    func test_whenDecodingLoader_thenItSucceeds() async throws {
        // Given
        struct CustomResponse: Decodable, Equatable {
            let key: String
        }
        let httpLoader = StaticLoader(data: Data(#"{"key": "value"}"#.utf8), response: .dummy())
        let loader: AnyLoader<HTTPRequest, CustomResponse> = httpLoader
            .map(\.body)
            .decode()
            .eraseToAnyLoader()

        // When
        let output = try await loader.load(HTTPRequest())

        // Then
        XCTAssertEqual(output, CustomResponse(key: "value"))
    }

    func test_modifyURLRequest() async throws {
        // Given
        var loadedRequest: URLRequest?
        let loader = AnyLoader { request in
            loadedRequest = request
            return (Data(), .dummy())
        }.httpLoader { request, urlRequest in
            if let cachePolicy = request.cachePolicy {
                urlRequest.cachePolicy = cachePolicy
            }
        }
        let request = HTTPRequest().configured {
            $0.cachePolicy = .returnCacheDataElseLoad
        }

        // When
        _ = try await loader.load(request)

        // Then
        XCTAssertEqual(loadedRequest?.cachePolicy, .returnCacheDataElseLoad)
    }

    func test_getWithBody_shouldThrowError() async throws {
        // Given
        let loader = testLoader.validateRequests()
        let request = HTTPRequest().configured {
            $0.body = .string("test")
        }

        do {
            // When
            _ = try await loader.load(request)
        } catch let error as RequestValidationError {
            // Then
            XCTAssertEqual(error, .requestWithGETMethodShouldNotHaveBody)
        } catch {
            XCTFail("Should have thrown validation error")
        }

    }
}

enum CachePolicyOption: HTTPRequestOption {
    static let defaultValue: URLRequest.CachePolicy? = nil
}

extension HTTPRequest {
    var cachePolicy: URLRequest.CachePolicy? {
        get { self[option: CachePolicyOption.self] }
        set { self[option: CachePolicyOption.self] = newValue }
    }
}

private extension ServerEnvironment {
    static let production = Self(host: "prod.example.com", pathPrefix: "v1", headers: ["X-API-KEY": "test"])
}

extension URLResponse {
    static func dummy(url: URL = URL(string: "test")!, statusCode: Int = 200, headers: [String: String]? = nil) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headers)!
    }
}

extension String: Error {}

private extension HTTPCookie {
    static let test1 = HTTPCookie(properties: [
        .name: "test1",
        .value: "1",
        .path: "/",
        .domain: "google.com"
    ])!

    static let test2 = HTTPCookie(properties: [
        .name: "test2",
        .value: "2",
        .path: "/",
        .domain: "google.com"
    ])!
}
