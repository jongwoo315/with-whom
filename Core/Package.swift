// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "WithWhomCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "WithWhomCore", targets: ["WithWhomCore"]),
    ],
    targets: [
        .target(name: "WithWhomCore"),
        .testTarget(
            name: "WithWhomCoreTests",
            dependencies: ["WithWhomCore"],
            resources: [.copy("Resources/titles.json")]
        ),
    ]
)
