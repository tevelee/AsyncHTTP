import Foundation

extension URLSession {
    public var data: Loaders.URLSessionData {
        .init(urlSession: self)
    }

    public var http: Loaders.HTTP<Loaders.URLSessionData> {
        data.http()
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