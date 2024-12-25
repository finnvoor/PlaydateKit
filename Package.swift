// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PlaydateKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PlaydateKit", targets: ["PlaydateKit"]),
        .plugin(name: "PDCPlugin", targets: ["PDCPlugin"])
    ],
    targets: [
        .target(
            name: "PlaydateKit",
            dependencies: ["CPlaydate", "SwiftUnicodeDataTables"],
            swiftSettings: [
                .enableExperimentalFeature("Embedded"),
                .unsafeFlags([
                    "-whole-module-optimization",
                    "-Xfrontend", "-disable-objc-interop",
                    "-Xfrontend", "-disable-stack-protector",
                    "-Xfrontend", "-function-sections",
                    "-Xfrontend", "-gline-tables-only",
                    "-Xcc", "-DTARGET_EXTENSION",
                    "-Xcc", "-I", "-Xcc", "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/lib/gcc/arm-none-eabi/9.2.1/include",
                    "-Xcc", "-I", "-Xcc", "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/lib/gcc/arm-none-eabi/9.2.1/include-fixed",
                    "-Xcc", "-I", "-Xcc", "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/lib/gcc/arm-none-eabi/9.2.1/../../../../arm-none-eabi/include",
                    "-I", "\(Context.environment["PLAYDATE_SDK_PATH"] ?? "\(Context.environment["HOME"]!)/Developer/PlaydateSDK/")/C_API"
                ]),
            ]
        ),
        .target(
            name: "CPlaydate",
            cSettings: [
                .unsafeFlags([
                    "-DTARGET_EXTENSION",
                    "-I", "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/lib/gcc/arm-none-eabi/9.2.1/include",
                    "-I", "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/lib/gcc/arm-none-eabi/9.2.1/include-fixed",
                    "-I", "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/lib/gcc/arm-none-eabi/9.2.1/../../../../arm-none-eabi/include",
                    "-I", "\(Context.environment["PLAYDATE_SDK_PATH"] ?? "\(Context.environment["HOME"]!)/Developer/PlaydateSDK/")/C_API"
                ])
            ]
        ),
        .target(
            name: "SwiftUnicodeDataTables",
            cxxSettings: [
                .define("SWIFT_STDLIB_ENABLE_UNICODE_DATA")
            ]
        ),
        .plugin(
            name: "PDCPlugin",
            capability: .command(intent:
                .custom(verb: "pdc", description: "Runs the Playdate compiler")
            )
        ),
    ],
    swiftLanguageModes: [.v6]
)
