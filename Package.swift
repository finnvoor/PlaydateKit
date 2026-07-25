// swift-tools-version: 6.1

import PackageDescription

let playdateSDKPath: String = if let path = Context.environment["PLAYDATE_SDK_PATH"] {
    path
} else {
    "\(Context.environment["HOME"]!)/Developer/PlaydateSDK/"
}

/// Flags shared by every Embedded Swift target in this package.
///
/// Debug builds are the ones that end up in `pdex.dylib`, and they keep the full
/// DWARF that SwiftPM's `-g` produces so LLDB can inspect variables while the
/// game runs in the Playdate Simulator.
///
/// Release builds are the ones that end up in `pdex.elf`, and only need line
/// tables. They are pinned to DWARF 4 because the Simulator's "Device - C"
/// Sampler symbolizes samples by shelling out to the Playdate SDK's
/// `arm-none-eabi-addr2line`, which ships with binutils 2.32 and fails to parse
/// the DWARF 5 that Clang emits by default.
let embeddedSwiftSettings: [SwiftSetting] = [
    .enableExperimentalFeature("Embedded"),
    .unsafeFlags([
        "-whole-module-optimization",
        "-Xfrontend", "-disable-objc-interop",
        "-Xfrontend", "-disable-stack-protector",
        "-Xfrontend", "-function-sections",
        "-Xcc", "-DTARGET_EXTENSION",
        "-I", "\(playdateSDKPath)/C_API"
    ]),
    .unsafeFlags(
        [
            "-Xfrontend", "-gline-tables-only",
            "-dwarf-version=4",
            "-Xcc", "-gdwarf-4"
        ],
        .when(configuration: .release)
    )
]

let package = Package(
    name: "PlaydateKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PlaydateKit", targets: ["PlaydateKit"]),
        .library(name: "CrankIndicator", targets: ["CrankIndicator"]),
        .plugin(name: "PDCPlugin", targets: ["PDCPlugin"]),
        .plugin(name: "RenamePlugin", targets: ["RenamePlugin"])
    ],
    targets: [
        .target(
            name: "PlaydateKit",
            dependencies: ["CPlaydate"],
            swiftSettings: embeddedSwiftSettings
        ),
        .target(
            name: "CrankIndicator",
            dependencies: ["PlaydateKit"],
            exclude: ["Resources"],
            swiftSettings: embeddedSwiftSettings
        ),
        .target(
            name: "CPlaydate",
            cSettings: [
                .unsafeFlags([
                    "-DTARGET_EXTENSION",
                    "-I", "\(playdateSDKPath)/C_API"
                ]),
                // See `embeddedSwiftSettings` for why the device build is pinned to DWARF 4.
                .unsafeFlags(["-gdwarf-4"], .when(configuration: .release))
            ]
        ),
        .plugin(
            name: "PDCPlugin",
            capability: .command(intent:
                .custom(verb: "pdc", description: "Runs the Playdate compiler"))
        ),
        .plugin(
            name: "RenamePlugin",
            capability: .command(
                intent: .custom(verb: "rename", description: "Rename a PlaydateKit Swift package"),
                permissions: [.writeToPackageDirectory(reason: "Rename PlaydateKit package")]
            )
        )
    ],
    swiftLanguageModes: [.v6]
)
