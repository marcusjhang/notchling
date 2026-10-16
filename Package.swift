// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Notchling",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .target(name: "NotchlingCore"),
        .target(
            name: "NotchlingUI",
            dependencies: ["NotchlingCore"]
        ),
        .executableTarget(
            name: "Notchling",
            dependencies: ["NotchlingCore", "NotchlingUI"]
        ),
        .executableTarget(
            name: "NotchlingProbe",
            dependencies: ["NotchlingCore"]
        ),
        .executableTarget(
            name: "NotchlingRender",
            dependencies: ["NotchlingCore", "NotchlingUI"]
        ),
        .testTarget(
            name: "NotchlingCoreTests",
            dependencies: ["NotchlingCore"]
        ),
    ]
)
