// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "JudoSupport",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "JudoSupport",
            targets: ["JudoSupport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections", from: "1.2.0"),
        .package(url: "https://github.com/schwa/Everything", from: "1.2.0"),
        .package(url: "https://github.com/LebJe/TOMLKit.git", from: "0.5.0"),
        .package(url: "https://github.com/swiftlang/swift-subprocess", branch: "main"),
        .package(url: "https://github.com/apple/swift-system", from: "1.4.0")

    ],
    targets: [
        .target(
            name: "JudoSupport",
            dependencies: [
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Everything", package: "Everything"),
                .product(name: "TOMLKit", package: "TOMLKit"),
                .product(name: "Subprocess", package: "swift-subprocess"),
                .product(name: "SystemPackage", package: "swift-system"),
            ]
        ),
        .testTarget(
            name: "JudoSupportTests",
            dependencies: ["JudoSupport"]
        ),
        .executableTarget(name: "JudoSupportPlayground",
            dependencies: ["JudoSupport"]
        ),
    ]
)
