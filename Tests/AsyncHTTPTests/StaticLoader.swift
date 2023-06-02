@testable import AsyncHTTP
import Foundation

final class StaticLoader: Loader {
    typealias Response = (data: Data, response: HTTPURLResponse)

    var index = 0
    let responses: [Response]

    init(_ response: Response, _ responses: Response...) {
        self.responses = [response] + responses
    }

    init(data: Data, response: HTTPURLResponse) {
        self.responses = [(data, response)]
    }

    func load(_ request: HTTPRequest) -> HTTPResponse {
        defer {
            if index == responses.count - 1 {
                index = 0
            } else {
                index += 1
            }
        }
        let response = responses[index]
        return HTTPResponse(request: request, response: response.response, body: response.data)
    }
}
