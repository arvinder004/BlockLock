// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BlockLock",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "BlockLock", targets: ["BlockLock"])
    ],
    targets: [
        .executableTarget(
            name: "BlockLock",
            path: "Sources/BlockLock"
        )
    ]
)
