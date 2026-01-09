// swift-tools-version: 6.1

import Foundation
import PackageDescription

/// Hack to force Xcode builds to not produce a dylib, since linking fails
/// without a toolset.json specified. Ideally this can be removed if/when
/// Xcode gains toolset.json support.
let xcode = (Context.environment["XPC_SERVICE_NAME"]?.count ?? 0) > 2

let package = Package(
    name: "Pong",
    platforms: [.macOS(.v14)],
    products: [.library(name: "Pong", type: xcode ? nil : .dynamic, targets: ["Pong"])],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .target(
            name: "Pong",
            dependencies: [.product(name: "PlaydateKit", package: "PlaydateKit")],
            exclude: ["Resources"],
            swiftSettings: [
                .enableExperimentalFeature("Embedded"),
                .unsafeFlags([
                    "-whole-module-optimization",
                    "-Xfrontend", "-disable-objc-interop",
                    "-Xfrontend", "-disable-stack-protector",
                    "-Xfrontend", "-function-sections",
                    "-Xcc", "-DTARGET_EXTENSION"
                ]),
            ],
        )
    ]
)
