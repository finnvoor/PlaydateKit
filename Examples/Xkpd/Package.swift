// swift-tools-version: 6.1

import PackageDescription

/// Hack to force Xcode builds to not produce a dylib, since linking fails
/// without a toolset.json specified. Ideally this can be removed if/when
/// Xcode gains toolset.json support.
let xcode = (Context.environment["XPC_SERVICE_NAME"]?.count ?? 0) > 2

let playdateSDKPath: String = if let path = Context.environment["PLAYDATE_SDK_PATH"] {
    path
} else {
    "\(Context.environment["HOME"]!)/Developer/PlaydateSDK/"
}

let package = Package(
    name: "Xkpd",
    platforms: [.macOS(.v14)],
    products: [.library(name: "Xkpd", type: xcode ? nil : .dynamic, targets: ["Xkpd"])],
    dependencies: [
        .package(path: "../.."),
        .package(url: "https://github.com/strawdynamics/UTF8ViewExtensions.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Xkpd",
            dependencies: [
                .product(name: "PlaydateKit", package: "PlaydateKit"),
                .product(name: "UTF8ViewExtensions", package: "UTF8ViewExtensions"),
                "CLodePNG",
                "CQRCode",
            ],
            exclude: ["Resources"],
            swiftSettings: [
                .enableExperimentalFeature("Embedded"),
                .unsafeFlags([
                    "-whole-module-optimization",
                    "-Xfrontend", "-disable-objc-interop",
                    "-Xfrontend", "-disable-stack-protector",
                    "-Xfrontend", "-function-sections",
                    "-Xfrontend", "-gline-tables-only",
                    "-Xcc", "-DTARGET_EXTENSION",
                    "-Xcc", "-I", "-Xcc", "\(playdateSDKPath)/C_API",
                ]),
            ],
        ),
        .target(
            name: "CLodePNG",
            exclude: [
                "lodepng",
            ],
            cSettings: [
                .unsafeFlags([
                    "-v",
                    "-DLODEPNG_NO_COMPILE_DISK",
                    "-DLODEPNG_NO_COMPILE_ALLOCATORS",
                    "-DLODEPNG_NO_COMPILE_ANCILLARY_CHUNKS",
                ])
            ],
        ),
        .target(
            name: "CQRCode",
            exclude: [
                "QRCode",
            ],
            cSettings: [
                .unsafeFlags([
                    "-v",
                ])
            ]
        ),
    ]
)
