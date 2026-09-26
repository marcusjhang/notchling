// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Notchling",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .target(name: "NotchlingCore"),
        .executableTarget(
            name: "Notchling",
            dependencies: ["NotchlingCore"]
        ),
        .executableTarget(
            name: "NotchlingProbe",
            dependencies: ["NotchlingCore"]
        ),
        .testTarget(
            name: "NotchlingCoreTests",
            dependencies: ["NotchlingCore"]
        ),
    ]
)
