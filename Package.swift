// swift-tools-version: 6.0

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "PlaydateKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PlaydateKit", targets: ["PlaydateKit"]),
        .plugin(name: "PDCPlugin", targets: ["PDCPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax", from: "600.0.0"),
    ],
    targets: [
        .target(
            name: "PlaydateKit", 
            dependencies: ["CPlaydate", "SwiftUnicodeDataTables", "PlaydateKitMacros"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "CPlaydate",
            cSettings: [
                .unsafeFlags([
                    "-DTARGET_EXTENSION",
                    "-I", "\(gccIncludePrefix)/include",
                    "-I", "\(gccIncludePrefix)/include-fixed",
                    "-I", "\(gccIncludePrefix)/../../../../arm-none-eabi/include",
                    "-I", "\(playdateSDKPath)/C_API"
                ])
            ]
        ),
        .target(
            name: "SwiftUnicodeDataTables",
            cxxSettings: [
                .define("SWIFT_STDLIB_ENABLE_UNICODE_DATA")
            ]
        ),
        
        .macro(
            name: "PlaydateKitMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
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

// MARK: - Helper Variables

// note: These must be computed variables when beneath the `let package =` declaration.

var swiftSettings: [SwiftSetting] { [
    .enableExperimentalFeature("Embedded"),
    .unsafeFlags([
        "-whole-module-optimization",
        "-Xfrontend", "-disable-objc-interop",
        "-Xfrontend", "-disable-stack-protector",
        "-Xfrontend", "-function-sections",
        "-Xfrontend", "-gline-tables-only",
        "-Xcc", "-DTARGET_EXTENSION",
        "-Xcc", "-I", "-Xcc", "\(gccIncludePrefix)/include",
        "-Xcc", "-I", "-Xcc", "\(gccIncludePrefix)/include-fixed",
        "-Xcc", "-I", "-Xcc", "\(gccIncludePrefix)/../../../../arm-none-eabi/include",
        "-I", "\(playdateSDKPath)/C_API"
    ]),
] }
var gccIncludePrefix: String {
    "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/lib/gcc/arm-none-eabi/9.2.1"
}

var playdateSDKPath: String {
    if let path = Context.environment["PLAYDATE_SDK_PATH"] {
        return path
    }
    return "\(Context.environment["HOME"]!)/Developer/PlaydateSDK/"
}
