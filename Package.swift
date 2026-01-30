// swift-tools-version: 6.1

import PackageDescription

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
    targets: [
        .target(
            name: "PlaydateKit",
            dependencies: ["CPlaydate"],
            swiftSettings: [
                .enableExperimentalFeature("Embedded"),
                .unsafeFlags([
                    "-whole-module-optimization",
                    "-Xfrontend", "-disable-objc-interop",
                    "-Xfrontend", "-disable-stack-protector",
                    "-Xfrontend", "-function-sections",
                    "-Xfrontend", "-gline-tables-only",
                    "-Xcc", "-DTARGET_EXTENSION",
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
                    "-Xfrontend", "-gline-tables-only",
                    "-Xcc", "-DTARGET_EXTENSION",
                    "-I", "\(playdateSDKPath)/C_API"
                ]),
            ]
        ),
        .target(
            name: "CPlaydate",
            cSettings: [
                .unsafeFlags([
                    "-DTARGET_EXTENSION",
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
