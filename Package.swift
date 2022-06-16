// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AsyncHTTP",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .macCatalyst(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(name: "AsyncHTTP", targets: ["AsyncHTTP"]),
    ],
    targets: [
        .target(name: "AsyncHTTP", dependencies: []),
        .testTarget(name: "AsyncHTTPTests", dependencies: ["AsyncHTTP"]),
    ]
)

#if swift(>=5.6)
package.dependencies.append(.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"))
#endif
