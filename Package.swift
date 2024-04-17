// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "SwiftStomp",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(name: "SwiftStomp", targets: ["SwiftStomp"])
    ],
    dependencies: [
        .package(url: "https://github.com/daltoniam/Starscream.git", .exact("4.0.6")),
        .package(url: "https://github.com/ashleymills/Reachability.swift", .upToNextMajor(from: "5.0.0"))
    ],
    targets: [
        .target(
            name: "SwiftStomp",
            dependencies: ["Starscream",
                           "Reachability"],
            path: "SwiftStomp"
        )
    ]
)

