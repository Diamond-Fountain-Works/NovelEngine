// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NovelCore",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "NovelDomain", targets: ["NovelDomain"]),
        .library(name: "NovelApplication", targets: ["NovelApplication"]),
        .library(name: "NovelStorage", targets: ["NovelStorage"]),
        .library(name: "NovelWorkspace", targets: ["NovelWorkspace"])
    ],
    targets: [
        .target(name: "NovelDomain"),
        .target(name: "NovelApplication", dependencies: ["NovelDomain"]),
        .target(name: "NovelStorage", dependencies: ["NovelDomain"]),
        .target(name: "NovelWorkspace"),
        .testTarget(name: "NovelCoreTests", dependencies: ["NovelDomain", "NovelApplication", "NovelStorage", "NovelWorkspace"])
    ]
)
