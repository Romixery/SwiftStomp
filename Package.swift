// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SwiftStomp",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13)
    ],
    products: [
        .library(name: "SwiftStomp", targets: ["SwiftStomp"])
    ],
    dependencies: [
        .package(url: "https://github.com/ashleymills/Reachability.swift", .upToNextMajor(from: "5.2.1"))
    ],
    targets: [
        .target(
            name: "SwiftStomp",
            dependencies: [
                .product(name: "Reachability", package: "Reachability.swift"),
            ],
            path: "SwiftStomp"
        )
    ]
)
