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
        // Swift 5 mode: Pigeon's generated async handlers (Messages.g.swift) aren't Swift 6 clean. The vendored SDK is
        // built and tested in Swift 6 mode in its own repo.
        .target(
            name: "antnexo",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                // The SDK reads UserDefaults (What's new read state): declared in the privacy manifest.
                .process("PrivacyInfo.xcprivacy"),
            ],
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
