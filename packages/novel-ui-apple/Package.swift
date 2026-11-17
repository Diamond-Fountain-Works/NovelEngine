// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NovelUIApple", defaultLocalization: "zh-Hans",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [.library(name: "NovelUI", targets: ["NovelUI"])],
    dependencies: [.package(path: "../novel-core-swift")],
    targets: [
        .target(name: "NovelUI", dependencies: [
            .product(name: "NovelDomain", package: "novel-core-swift"),
            .product(name: "NovelApplication", package: "novel-core-swift"),
            .product(name: "NovelWorkspace", package: "novel-core-swift")
        ], resources: [.process("Resources")]),
        .testTarget(name: "NovelUITests", dependencies: ["NovelUI"])
    ]
)
