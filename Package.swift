// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VoiceoverStudio",
    platforms: [.macOS("14.4")],
    products: [.executable(name: "VoiceoverStudio", targets: ["VoiceoverStudio"])],
    targets: [
        .executableTarget(name: "VoiceoverStudio", path: "Sources"),
        .testTarget(name: "VoiceoverStudioTests", dependencies: ["VoiceoverStudio"], path: "Tests")
    ],
    swiftLanguageModes: [.v6]
)
