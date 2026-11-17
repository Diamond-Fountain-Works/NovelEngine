// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NovelEngineMac", defaultLocalization: "zh-Hans", platforms: [.macOS(.v13)],
    products: [.executable(name: "NovelEngine", targets: ["NovelEngine"])],
    dependencies: [.package(path: "../../../packages/novel-core-swift"), .package(path: "../../../packages/novel-ui-apple")],
    targets: [
        .executableTarget(name: "NovelEngine", dependencies: [
            .product(name: "NovelUI", package: "novel-ui-apple"),
            .product(name: "NovelDomain", package: "novel-core-swift"),
            .product(name: "NovelStorage", package: "novel-core-swift")
        ]),
        .testTarget(name: "NativeDocumentTests", dependencies: ["NovelEngine", .product(name: "NovelDomain", package: "novel-core-swift")])
    ]
)
