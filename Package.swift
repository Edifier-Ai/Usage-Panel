// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CodexIslandUsageWidget",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "CodexIslandUsageCore",
            targets: ["CodexIslandUsageCore"]
        ),
        .executable(
            name: "CodexIslandUsageWidget",
            targets: ["CodexIslandUsageWidget"]
        )
    ],
    targets: [
        .target(
            name: "CodexIslandUsageCore"
        ),
        .executableTarget(
            name: "CodexIslandUsageWidget",
            dependencies: ["CodexIslandUsageCore"]
        ),
        .testTarget(
            name: "CodexIslandUsageCoreTests",
            dependencies: ["CodexIslandUsageCore"]
        )
    ]
)
