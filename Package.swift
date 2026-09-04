// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WindowHolder",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "WindowHolder",
            path: "Sources/WindowHolder"
        )
    ]
)
