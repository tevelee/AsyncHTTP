# AsyncHTTP

Generic networking library written using Swift async/await

```swift
let request = try HTTPRequest().configured {
    $0.path = "endpoint"
    $0.body = try .json(["a": "b"])
    $0[header: .accept] = .application.json.appending(.characterSet, value: .utf8)
    $0[header: .authorization] = .bearer(token: "token")
    $0.addQueryParameter(name: "q", value: "search")
    $0.serverEnvironment = .production
    $0.timeout = 60
    $0.retryStrategy = .immediately(maximumNumberOfAttempts: 3)
}

let loader: some HTTPLoader = URLSession.data.http
    .applyServerEnvironment()
    .applyTimeout(default: 30)
    .applyRetryStrategy()
    .deduplicate()
    .throttle(maximumNumberOfRequests: 2)

let response: HTTPResponse = try await loader.load(request)
```