import Foundation

public struct HTTPResponse {
    public let request: HTTPRequest
    public let response: HTTPURLResponse
    public let body: Data
}
