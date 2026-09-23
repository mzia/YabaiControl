// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "YabaiControl",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "YabaiControl"
        ),
        .testTarget(
            name: "YabaiControlTests",
            dependencies: ["YabaiControl"]
        ),
    ]
)
