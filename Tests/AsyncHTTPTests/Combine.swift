@testable import AsyncHTTP
import Foundation
import XCTest
#if canImport(Combine)
import Combine

final class CombineTests: XCTestCase {
    private let testLoader = StaticLoader(data: Data(), response: .dummy())

    func test_combine() async throws {
        // Given

        // When
        let output = try await testLoader.loadPublisher(HTTPRequest()).asyncSingle()

        // Then
        XCTAssertEqual(output.status.code, 200)
        XCTAssertEqual(output.status.message, "OK")
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

#endif
