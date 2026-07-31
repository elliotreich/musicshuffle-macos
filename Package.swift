// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MusicShuffle",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MusicShuffle", targets: ["MusicShuffle"])
    ],
    targets: [
        .executableTarget(
            name: "MusicShuffle",
            path: "Sources"
        )
    ]
)
