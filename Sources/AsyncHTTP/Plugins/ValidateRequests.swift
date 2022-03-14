import Foundation

extension Loader where Input == HTTPRequest, Output == HTTPResponse {
    public func validateRequests() -> Loaders.ValidateRequests<Self> {
        Loaders.ValidateRequests<Self>(self)
    }
}

extension Loaders {
    public struct ValidateRequests<Upstream: Loader>: HTTPLoader where Upstream.Input == HTTPRequest, Upstream.Output == HTTPResponse {
        private let upstream: Upstream

        init(_ upstream: Upstream) {
            self.upstream = upstream
        }

        public func load(_ request: HTTPRequest) async throws -> HTTPResponse {
            let output = try await upstream.load(request)
            let type = String(describing: type(of: self))
            if request.timeout != nil, !type.contains("ApplyTimeout<") {
                throw Self.Error.loaderShouldContainApplyTimeout
            }
            if request.retryStrategy != nil, !type.contains("ApplyRetryStrategy<") {
                throw Self.Error.loaderShouldContainApplyRetryStrategy
            }
            return output
        }

        public enum Error: Swift.Error {
            case loaderShouldContainApplyTimeout
            case loaderShouldContainApplyRetryStrategy
        }
    }
}
