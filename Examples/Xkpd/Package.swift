// swift-tools-version: 6.1

import Foundation
import PackageDescription

/// Hack to force Xcode builds to not produce a dylib, since linking fails
/// without a toolset.json specified. Ideally this can be removed if/when
/// Xcode gains toolset.json support.
let xcode = (Context.environment["XPC_SERVICE_NAME"]?.count ?? 0) > 2

let armSysrootPath: String = if let path = Context.environment["ARM_NONE_EABI_SYSROOT_PATH"] {
    path
} else {
    #if os(Linux)
    "/usr/lib/arm-none-eabi"
    #else
    "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/arm-none-eabi"
    #endif
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
                    "-Xcc", "-DTARGET_EXTENSION"
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
                    "-I", "\(armSysrootPath)/include",
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
                    "-I", "\(armSysrootPath)/include",
                ])
            ]
        ),
    ]
)
