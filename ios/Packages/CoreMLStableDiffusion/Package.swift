// swift-tools-version: 5.8
import PackageDescription

/// Local rename of apple/ml-stable-diffusion's StableDiffusion module so it can
/// coexist with mlx-swift-examples (which also declares a target named
/// StableDiffusion — SPM forbids duplicate target names in one graph).
let package = Package(
    name: "CoreMLStableDiffusion",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "CoreMLStableDiffusion",
            targets: ["CoreMLStableDiffusion"]),
    ],
    targets: [
        .target(
            name: "CoreMLStableDiffusion",
            path: "Sources/CoreMLStableDiffusion"),
    ]
)
