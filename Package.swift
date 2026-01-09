// swift-tools-version: 6.1

import PackageDescription
import CompilerPluginSupport

let armToolchainPath: String = if let path = Context.environment["ARM_NONE_EABI_GCC_PATH"] {
    path
} else {
    #if os(Linux)
    "/usr/lib/gcc/arm-none-eabi/10.3.1"
    #else
    "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/lib/gcc/arm-none-eabi/9.2.1"
    #endif
}

let armSysrootPath: String = if let path = Context.environment["ARM_NONE_EABI_SYSROOT_PATH"] {
    path
} else {
    #if os(Linux)
    "/usr/lib/arm-none-eabi"
    #else
    "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/arm-none-eabi"
    #endif
}

let playdateSDKPath: String = if let path = Context.environment["PLAYDATE_SDK_PATH"] {
    path
} else {
    "\(Context.environment["HOME"]!)/Developer/PlaydateSDK/"
}

let package = Package(
    name: "PlaydateKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "PlaydateKit", targets: ["PlaydateKit"]),
        .library(name: "CrankIndicator", targets: ["CrankIndicator"]),
        .plugin(name: "PDCPlugin", targets: ["PDCPlugin"]),
        .plugin(name: "RenamePlugin", targets: ["RenamePlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.1"),
    ],
    targets: [
        .macro(
            name: "PlaydateKitMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "PlaydateKit",
            dependencies: ["CPlaydate", "PlaydateKitMacros"],
            swiftSettings: [
                .enableExperimentalFeature("Embedded"),
                .unsafeFlags([
                    "-whole-module-optimization",
                    "-Xfrontend", "-disable-objc-interop",
                    "-Xfrontend", "-disable-stack-protector",
                    "-Xfrontend", "-function-sections",
                    "-Xcc", "-DTARGET_EXTENSION",
                    "-Xcc", "-I", "-Xcc", "\(armToolchainPath)/include",
                    "-Xcc", "-I", "-Xcc", "\(armToolchainPath)/include-fixed",
                    "-Xcc", "-I", "-Xcc", "\(armSysrootPath)/include",
                    "-I", "\(playdateSDKPath)/C_API"
                ]),
            ]
        ),
        .target(
            name: "CrankIndicator",
            dependencies: ["PlaydateKit"],
            exclude: ["Resources"],
            swiftSettings: [
                .enableExperimentalFeature("Embedded"),
                .unsafeFlags([
                    "-whole-module-optimization",
                    "-Xfrontend", "-disable-objc-interop",
                    "-Xfrontend", "-disable-stack-protector",
                    "-Xfrontend", "-function-sections",
                    "-Xcc", "-DTARGET_EXTENSION",
                    "-Xcc", "-I", "-Xcc", "\(armToolchainPath)/include",
                    "-Xcc", "-I", "-Xcc", "\(armToolchainPath)/include-fixed",
                    "-Xcc", "-I", "-Xcc", "\(armSysrootPath)/include",
                    "-I", "\(playdateSDKPath)/C_API"
                ]),
            ]
        ),
        .target(
            name: "CPlaydate",
            cSettings: [
                .unsafeFlags([
                    "-DTARGET_EXTENSION",
                    "-I", "\(armToolchainPath)/include",
                    "-I", "\(armToolchainPath)/include-fixed",
                    "-I", "\(armSysrootPath)/include",
                    "-I", "\(playdateSDKPath)/C_API"
                ])
            ]
        ),
        .plugin(
            name: "PDCPlugin",
            capability: .command(intent:
                .custom(verb: "pdc", description: "Runs the Playdate compiler")
            )
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
