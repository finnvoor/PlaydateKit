import Foundation
import PackagePlugin

// MARK: - BuildDestination

enum BuildDestination {
    case simulator
    case device
}

// MARK: - ModuleType

enum ModuleType {
    case playdateKit
    case product
    case productDependency
}

// MARK: - ModuleBuildRequest

struct ModuleBuildRequest {
    let name: String
    let type: ModuleType
    let relativePath: Path
    let sourcefiles: [String]

    func moduleName(for dest: BuildDestination) -> String { "\(name.lowercased())_\(dest)" }

    func modulePath(for dest: BuildDestination) -> String {
        let suffix = switch type {
        case .product: "o"
        default: "swiftmodule"
        }
        return relativePath.appending(["\(moduleName(for: dest)).\(suffix)"]).string
    }
}

// MARK: - PDCPlugin

@main struct PDCPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var arguments = ArgumentExtractor(arguments)
        let verbose = arguments.extractFlag(named: "verbose") > 0

        let tools = Tools(context: context, verbose: verbose)
        let playdateSDK = try tools.playdateSDK()

        // MARK: - Paths

        let productName = context.package.displayName

        let moduleCachePath = context.pluginWorkDirectory.appending(["module-cache"])
        let modulesPath = context.pluginWorkDirectory.appending(["Modules"])

        let sourcePath = context.pluginWorkDirectory.appending(["Source"])
        let productPath: String = if let targetBuildDir = ProcessInfo.processInfo.environment["TARGET_BUILD_DIR"] {
            // Run from Xcode
            targetBuildDir + "/\(productName).pdx"
        } else {
            context.pluginWorkDirectory.appending(["\(productName).pdx"]).string
        }

        // MARK: - Source files

        let playdateKitPackage = context.package.dependencies.first(where: { $0.package.id == "playdatekit" })!
        let playdateKitSource = playdateKitPackage.package.sourceModules.first(where: { $0.name == "PlaydateKit" })!
        let playdateKitSwiftFiles = playdateKitSource.sourceFiles(withSuffix: "swift").map(\.path.string)
        let cPlaydateInclude = playdateKitPackage.package.sourceModules
            .first(where: { $0.name == "CPlaydate" })!.directory.appending("include")

        let productSource = context.package.sourceModules.first!
        let productSwiftFiles = productSource.sourceFiles(withSuffix: "swift").map(\.path.string)
        let productResources = productSource.sourceFiles
            .filter { $0.type == .unknown }
            .map(\.path)

        let playdateKit = ModuleBuildRequest(name: "playdatekit", type: .playdateKit, relativePath: modulesPath, sourcefiles: playdateKitSwiftFiles)
        let product = ModuleBuildRequest(name: productName, type: .product, relativePath: context.pluginWorkDirectory, sourcefiles: productSwiftFiles)
        let productDependencies = context.package.dependencies.compactMap { dep -> ModuleBuildRequest? in
            guard dep.package.id != "playdatekit" else { return nil }
            let sourceModule = dep.package.sourceModules.first!
            let sourceFiles = sourceModule.sourceFiles(withSuffix: "swift").map(\.path.string)
            return ModuleBuildRequest(name: sourceModule.name, type: .productDependency, relativePath: modulesPath, sourcefiles: sourceFiles)
        }

        // MARK: - Flags

        let mcu = "cortex-m7"
        let fpu = ["-mfloat-abi=hard", "-mfpu=fpv5-sp-d16", "-D__FPU_USED=1"]
        let mcFlags = ["-mthumb", "-mcpu=\(mcu)"] + fpu

        let gccIncludePaths = [
            "/include",
            "/include-fixed",
            "/../../../../arm-none-eabi/include"
        ].map { (ProcessInfo.processInfo.environment["ARM_TOOLCHAIN_PATH"] ?? "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/lib/gcc/arm-none-eabi/9.2.1") + $0 }

        guard FileManager.default.fileExists(atPath: gccIncludePaths.first!) else {
            Diagnostics.error("Arm embedded toolchain not found. Ensure it is installed through the Playdate SDK (macOS) or manually and set in the ARM_TOOLCHAIN_PATH environment variable.")
            throw Tools.Error.armNoneEabiGCCNotFound
        }

        let cFlags = gccIncludePaths.flatMap { ["-I", URL(fileURLWithPath: $0).standardized.path] }

        let swiftFlags = cFlags.flatMap { ["-Xcc", $0] } + [
            "-O",
            "-wmo",
            "-enable-experimental-feature", "Embedded",
            "-Xfrontend", "-disable-stack-protector",
            "-Xfrontend", "-function-sections",
            "-swift-version", "6",
            "-Xcc", "-DTARGET_EXTENSION",
            "-module-cache-path", moduleCachePath.string,
            "-I", "\(playdateSDK)/C_API",
            "-I", modulesPath.string,
            "-I", cPlaydateInclude.string
        ]

        let cFlagsDevice = mcFlags + ["-falign-functions=16", "-fshort-enums"]

        let swiftFlagsDevice = cFlagsDevice.flatMap { ["-Xcc", $0] } + [
            "-target", "armv7em-none-none-eabi",
            "-Xfrontend", "-experimental-platform-c-calling-convention=arm_aapcs_vfp",
            "-module-alias", "PlaydateKit=\(playdateKit.moduleName(for: .device))"
        ]

        let cFlagsSimulator: [String] = []

        let swiftFlagsSimulator = cFlagsSimulator.flatMap { ["-Xcc", $0] } + [
            "-module-alias", "PlaydateKit=\(playdateKit.moduleName(for: .simulator))"
        ]

        // MARK: - Build

        // setup.o
        let setup = context.pluginWorkDirectory.appending(["setup.o"]).string
        try tools.cc(mcFlags + [
            "-c", "-O2", "-falign-functions=16", "-fomit-frame-pointer", "-gdwarf-2", "-Wall", "-Wno-unused", "-Wstrict-prototypes", "-Wno-unknown-pragmas", "-fverbose-asm", "-Wdouble-promotion", "-mword-relocations", "-fno-common", "-ffunction-sections", "-fdata-sections", "-Wa,-ahlms=\(context.pluginWorkDirectory.appending(["setup.lst"]).string)", "-DTARGET_PLAYDATE=1", "-DTARGET_EXTENSION=1", "-MD", "-MP", "-MF",
            context.pluginWorkDirectory.appending(["setup.o.d"]).string,
            "-I", ".",
            "-I", ".",
            "-I", "\(playdateSDK)/C_API",
            "\(playdateSDK)/C_API/buildsupport/setup.c",
            "-o", setup
        ])

        if FileManager.default.fileExists(atPath: sourcePath.string) {
            try FileManager.default.removeItem(
                atPath: sourcePath.string
            )
        }
        try FileManager.default.createDirectory(
            atPath: sourcePath.string,
            withIntermediateDirectories: true
        )
        print("copying resources")
        for resource in productResources {
            try FileManager.default.copyItem(
                atPath: resource.string,
                toPath: sourcePath.appending([resource.lastComponent]).string
            )
        }

        func build(module: ModuleBuildRequest) async throws {
            async let deviceBuild: () = try buildDeviceModule(module)
            async let simulatorBuild: () = try buildSimulatorModule(module)
            let _ = try await (deviceBuild, simulatorBuild)
        }

        @Sendable func buildDeviceModule(_ module: ModuleBuildRequest) async throws {
            try await Task {
                print("building \(module.moduleName(for: .device))")
                switch module.type {
                case .playdateKit:
                    // playdatekit_device.swiftmodule
                    try tools.swiftc(swiftFlags + swiftFlagsDevice + module.sourcefiles + [
                        "-module-name", module.moduleName(for: .device), "-emit-module", "-emit-module-path", module.modulePath(for: .device)
                    ])
                case .product:
                    // $(productName)_device.o
                    let linkedModules = productDependencies.map { ["-module-alias", "\($0.name)=\($0.moduleName(for: .device))"] }.flatMap { $0 }
                    try tools.swiftc(swiftFlags + swiftFlagsDevice + linkedModules + module.sourcefiles + [
                        "-c", "-o", module.modulePath(for: .device)
                    ])
                    print("building pdex.elf")
                    try tools.cc([setup, module.modulePath(for: .device)] + mcFlags + [
                        "-T\(playdateSDK)/C_API/buildsupport/link_map.ld",
                        "-Wl,-Map=\(context.pluginWorkDirectory.appending(["pdex.map"]).string),--cref,--gc-sections,--no-warn-mismatch,--emit-relocs",
                        "-o", sourcePath.appending(["pdex.elf"]).string
                    ])
                case .productDependency:
                    try tools.swiftc(swiftFlags + swiftFlagsDevice + module.sourcefiles + [
                        "-module-name", module.moduleName(for: .device), "-emit-module", "-emit-module-path", module.modulePath(for: .device)
                    ])
                }
            }.value
        }

        @Sendable func buildSimulatorModule(_ module: ModuleBuildRequest) async throws {
            print("building \(module.moduleName(for: .simulator))")
            try await Task {
                switch module.type {
                case .playdateKit:
                    try tools.swiftc(swiftFlags + swiftFlagsSimulator + module.sourcefiles + [
                        "-module-name", module.moduleName(for: .simulator), "-emit-module", "-emit-module-path", module.modulePath(for: .simulator)
                    ])
                case .product:
                    // $(productName)_simulator.o
                    let linkedModules = productDependencies.map { ["-module-alias", "\($0.name)=\($0.moduleName(for: .simulator))"] }.flatMap { $0 }
                    try tools.swiftc(swiftFlags + swiftFlagsSimulator + linkedModules + module.sourcefiles + [
                        "-c", "-o", module.modulePath(for: .simulator)
                    ])
                    print("building pdex.dylib")

                    #if os(Linux)
                    let linkerFlags = ["-Wl,--undefined=_eventHandlerShim", "-Wl,--undefined=_eventHandler", "-shared", "-o", sourcePath.appending(["pdex.so"]).string]
                     #else
                    let linkerFlags = ["-Wl,-exported_symbol,_eventHandlerShim", "-Wl,-exported_symbol,_eventHandler", "-dynamiclib", "-rdynamic", "-o", sourcePath.appending(["pdex.dylib"]).string]
                     #endif

                    try tools.clang([
                        "-nostdlib", "-dead_strip"
                    ] + linkerFlags + [
                        module.modulePath(for: .simulator), "-lc", "-lm",
                        "-DTARGET_SIMULATOR=1", "-DTARGET_EXTENSION=1",
                        "-I", ".",
                        "-I", "\(playdateSDK)/C_API",
                        "\(playdateSDK)/C_API/buildsupport/setup.c"
                    ])
                case .productDependency:
                    try tools.swiftc(swiftFlags + swiftFlagsSimulator + module.sourcefiles + [
                        "-module-name", module.moduleName(for: .simulator), "-emit-module", "-emit-module-path", module.modulePath(for: .simulator)
                    ])
                }
            }.value
        }

        try await build(module: playdateKit)
        for dep in productDependencies {
            try await build(module: dep)
        }
        try await build(module: product)

        print("running pdc")
        try tools.pdc([
            sourcePath.string,
            productPath
        ])
    }
}

// MARK: PDCPlugin.Error

extension PDCPlugin {
    enum Error: Swift.Error {
        case swiftToolchainNotFound
        case playdateSDKNotFound
        case ccFailed(exitCode: Int32)
        case xcrunFailed(exitCode: Int32)
        case swiftcFailed(exitCode: Int32)
        case clangFailed(exitCode: Int32)
        case pdcFailed(exitCode: Int32)
    }
}

extension Process {
    func print() {
        Swift.print(([executableURL?.path() ?? ""] + (arguments ?? [])).joined(separator: " "))
    }
}
