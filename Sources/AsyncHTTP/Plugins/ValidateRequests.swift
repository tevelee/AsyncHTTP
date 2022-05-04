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
                throw LoaderValidationError.loaderShouldContainApplyTimeout
            }
            if request.retryStrategy != nil, !type.contains("ApplyRetryStrategy<") {
                throw LoaderValidationError.loaderShouldContainApplyRetryStrategy
            }
            if request.method == .get, !request.body.content.isEmpty {
                throw RequestValidationError.requestWithGETMethodShouldNotHaveBody
            }
            return output
        }
    }
}

public enum LoaderValidationError: Error {
    case loaderShouldContainApplyTimeout
    case loaderShouldContainApplyRetryStrategy
}

public enum RequestValidationError: Error {
    case requestWithGETMethodShouldNotHaveBody
}
