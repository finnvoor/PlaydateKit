// swift-tools-version: 5.10

import PackageDescription

let gccIncludePrefix =
    "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/lib/gcc/arm-none-eabi/9.2.1"

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
        .plugin(name: "PDCPlugin", targets: ["PDCPlugin"])
    ],
    targets: [
        .target(name: "PlaydateKit", dependencies: ["CPlaydate"], swiftSettings: [
            .enableExperimentalFeature("Embedded"),
            .unsafeFlags([
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
        ]),
        .target(name: "CPlaydate", cSettings: [
            .unsafeFlags([
                "-DTARGET_EXTENSION",
                "-I", "\(gccIncludePrefix)/include",
                "-I", "\(gccIncludePrefix)/include-fixed",
                "-I", "\(gccIncludePrefix)/../../../../arm-none-eabi/include",
                "-I", "\(playdateSDKPath)/C_API"
            ])
        ]),
        .plugin(
            name: "PDCPlugin",
            capability: .command(intent: .custom(verb: "pdc", description: "Runs the Playdate compiler"))
        )
    ]
)
