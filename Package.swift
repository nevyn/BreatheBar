// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BreatheBar",
    platforms: [
        .macOS(.v26)
    ],
    targets: [
        .executableTarget(
            name: "BreatheBar"
        )
    ]
)
