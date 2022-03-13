import Foundation

extension Loader where Input == HTTPRequest, Output == HTTPResponse {
    public func checked() -> Loaders.Checked<Self> {
        Loaders.Checked<Self>(self)
    }
}

extension Loaders {
    public struct Checked<Upstream: Loader>: HTTPLoader where Upstream.Input == HTTPRequest, Upstream.Output == HTTPResponse {
        private let upstream: Upstream

        init(_ upstream: Upstream) {
            self.upstream = upstream
        }

        public func load(_ request: HTTPRequest) async throws -> HTTPResponse {
            let output = try await upstream.load(request)
            let type = String(describing: type(of: self))
            if request.serverEnvironment != nil, !type.contains("ApplyServerEnvironment<") {
                throw Self.Error.loaderShouldContainApplyServerEnvironment
            }
            if request.timeout != nil, !type.contains("ApplyTimeout<") {
                throw Self.Error.loaderShouldContainApplyTimeout
            }
            if request.retryStrategy != nil, !type.contains("ApplyRetryStrategy<") {
                throw Self.Error.loaderShouldContainApplyRetryStrategy
            }
            return output
        }

        public enum Error: Swift.Error {
            case loaderShouldContainApplyServerEnvironment
            case loaderShouldContainApplyTimeout
            case loaderShouldContainApplyRetryStrategy
        }
    }
}
