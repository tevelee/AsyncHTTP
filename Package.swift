// swift-tools-version:5.6
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
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(name: "AsyncHTTP", dependencies: []),
        .testTarget(name: "AsyncHTTPTests", dependencies: ["AsyncHTTP"]),
    ]
)
