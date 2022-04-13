@testable import AsyncHTTP
import Foundation

struct StaticLoader: Loader {
    let data: Data
    let response: HTTPURLResponse

    init(_ data: Data, _ response: HTTPURLResponse) {
        self.data = data
        self.response = response
    }

    func load(_ request: HTTPRequest) -> HTTPResponse {
        HTTPResponse(request: request, response: response, body: data)
    }
}

extension StaticLoader: HTTPLoader {}

