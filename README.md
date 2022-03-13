# AsyncHTTP

Generic networking library written using Swift async/await

```swift
let request = try HTTPRequest().configured { request in
    request.path = "endpoint"
    request.method = .post
    request.body = try .json(["a": "b"])
    request[header: .accept] = .application.json.appending(.characterSet, value: .utf8)
    request[header: .authorization] = .bearer(token: "token")
    request.addQueryParameter(name: "q", value: "search")
    request.serverEnvironment = .production
    request.timeout = 60
    request.retryStrategy = .immediately(maximumNumberOfAttempts: 3)
}

let loader: some HTTPLoader = URLSession.shared.http
    .applyServerEnvironment()
    .applyTimeout(default: 30)
    .applyRetryStrategy()
    .deduplicate()
    .throttle(maximumNumberOfRequests: 2)

let response: HTTPResponse = try await loader.load(request)
let body: MyResponseStruct = response.jsonBody()

print(request.formatted())
print(response.formatted())
```
