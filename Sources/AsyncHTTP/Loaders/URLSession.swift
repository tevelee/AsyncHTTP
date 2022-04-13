import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking

extension URLSession {
    func data(for urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = dataTask(with: urlRequest) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }
                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
    }
}
#endif

extension URLSession {
    public var dataLoader: Loaders.URLSessionData {
        .init(urlSession: self)
    }

    public var httpLoader: Loaders.HTTP<Loaders.URLSessionData> {
        dataLoader.httpLoader()
    }
}

extension Loaders {
    public struct URLSessionData: Loader {
        private let urlSession: URLSession

        init(urlSession: URLSession = .shared) {
            self.urlSession = urlSession
        }

        public func load(_ request: URLRequest) async throws -> (Data, URLResponse) {
            try await urlSession.data(for: request)
        }
    }
}
