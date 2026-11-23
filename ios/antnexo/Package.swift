// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "antnexo",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "antnexo", targets: ["antnexo"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "antnexo",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                // The SDK reads UserDefaults (What's new read state): declared in the privacy manifest.
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
