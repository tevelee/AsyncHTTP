import AsyncHTTP
import Combine
import XCTest

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
            .map { response in
                guard response.statusCode.in(200 ..< 300) else {
                    throw "not 2XX response code"
                }
                return response
            }
            .intercept { $0.headers["X-Header"] = "value" }
//            .delay(seconds: 10)
            .deduplicate()
            .throttle(maximumNumberOfRequests: 1)

        // When
        _ = try await loader.load(request)

        // Then
        XCTAssertEqual(loadedRequest?.url?.absoluteString, "https://prod.example.com/v1/endpoint?q=search&sid=1")
        XCTAssertEqual(loadedRequest?[header: "Accept"], "application/json; charset=\"utf-8\"")
        XCTAssertEqual(loadedRequest?[header: "Authorization"], "Bearer token")
        XCTAssertEqual(loadedRequest?[header: "X-API-KEY"], "test")
        XCTAssertEqual(loadedRequest?[header: "X-Header"], "value")
        XCTAssertEqual(loadedRequest?.body.content, Data(#"{"a":"b"}"#.utf8))
    }

    func test_whenDecodingResponse_thenItSucceeds() async throws {
        // Given
        struct CustomResponse: Decodable, Equatable {
            let key: String
        }
        let loader: some HTTPLoader = AnyLoader { _ in (Data(#"{"key": "value"}"#.utf8), .dummy(headers: ["User-Agent": "X"])) }.http

        // When
        let output = try await loader.load(HTTPRequest())

        // Then
        XCTAssertEqual(try output.jsonBody(), CustomResponse(key: "value"))
        XCTAssertEqual(output[header: .userAgent], "X")
    }

    func test_whenDecodingLoader_thenItSucceeds() async throws {
        // Given
        struct CustomResponse: Decodable, Equatable {
            let key: String
        }
        let httpLoader: some HTTPLoader = AnyLoader { _ in (Data(#"{"key": "value"}"#.utf8), .dummy()) }.http
        let loader: AnyLoader<HTTPRequest, CustomResponse> = httpLoader
            .map(\.body)
            .decode()
            .eraseToAnyLoader()

        // When
        let output = try await loader.load(HTTPRequest())

        // Then
        XCTAssertEqual(output, CustomResponse(key: "value"))
    }

    func test_combine() async throws {
        // Given

        // When
        let output = try await testLoader.loadPublisher(HTTPRequest()).asyncSingle()

        // Then
        XCTAssertEqual(output.statusCode, 200)
    }
}

private extension ServerEnvironment {
    static let production = Self(host: "prod.example.com", pathPrefix: "v1", headers: ["X-API-KEY": "test"])
}

private extension URLResponse {
    static func dummy(url: URL = URL(string: "test")!, statusCode: Int = 200, headers: [String: String]? = nil) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: headers)!
    }
}

extension String: Error {}

private extension Int {
    func `in`(_ range: Range<Int>) -> Bool {
        range.contains(self)
    }
}

private extension Publisher where Failure == Error {
    func asyncStream() -> AsyncThrowingStream<Output, Error> {
        .init { continuation in
            let cancellable = sink { completion in
                switch completion {
                    case .finished:
                        continuation.finish()
                    case .failure(let error):
                        continuation.finish(throwing: error)
                }
            } receiveValue: { value in
                continuation.yield(value)
            }
            continuation.onTermination = { @Sendable _ in
                cancellable.cancel()
            }
        }
    }

    func asyncSingle() async throws -> Output {
        var cancellable: AnyCancellable?
        let value: Output = try await withCheckedThrowingContinuation { continuation in
            var output: Output!
            cancellable = sink { completion in
                switch completion {
                    case .finished:
                        continuation.resume(returning: output)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                }
            } receiveValue: { value in
                output = value
            }
        }
        cancellable?.cancel()
        return value
    }
}
