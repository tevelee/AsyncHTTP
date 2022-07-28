import Foundation

extension Loader where Input == HTTPRequest, Output == HTTPResponse {
#if compiler(>=5.7)
    @_disfavoredOverload
    public func validateRequests() -> some Loader<Input, Output> {
        Loaders.ValidateRequests(loader: self)
    }
#endif

    public func validateRequests() -> Loaders.ValidateRequests<Self> {
        .init(loader: self)
    }
}

extension Loaders {
    public struct ValidateRequests<Upstream: Loader>: Loader where Upstream.Input == HTTPRequest, Upstream.Output == HTTPResponse {
        private let loader: Upstream

        public init(loader: Upstream) {
            self.loader = loader
        }

        public func load(_ request: HTTPRequest) async throws -> HTTPResponse {
            let output = try await loader.load(request)
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
