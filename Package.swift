// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AsyncHTTP",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(name: "AsyncHTTP", targets: ["AsyncHTTP"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "AsyncHTTP", dependencies: []),
        .testTarget(name: "AsyncHTTPTests", dependencies: ["AsyncHTTP"]),
    ]
)
