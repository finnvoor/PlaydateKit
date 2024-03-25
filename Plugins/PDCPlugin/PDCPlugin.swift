import Foundation
import PackagePlugin

// MARK: - PDCPlugin

@main struct PDCPlugin: CommandPlugin {
    let home = FileManager.default.homeDirectoryForCurrentUser.path()
    let arm_none_eabi_gcc = "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/bin/arm-none-eabi-gcc"

    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var arguments = ArgumentExtractor(arguments)
        let verbose = arguments.extractFlag(named: "verbose") > 0

        // MARK: - Paths

        let swiftToolchain = try swiftToolchain()
        print("found Swift toolchain: \(swiftToolchain)")

        let playdateSDK = try playdateSDK()
        print("found Playdate SDK")

        let productName = context.package.displayName

        let moduleCachePath = context.pluginWorkDirectory.appending(["module-cache"])
        let modulesPath = context.pluginWorkDirectory.appending(["Modules"])

        let playdateKitDevicePath = modulesPath.appending(["playdatekit_device.o"])
        let playdateKitSimulatorPath = modulesPath.appending(["playdatekit_simulator.o"])

        let productDevicePath = context.pluginWorkDirectory.appending(["\(productName.lowercased())_device.o"])
        let productSimulatorPath = context.pluginWorkDirectory.appending(["\(productName.lowercased())_simulator.o"])

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

        // MARK: - Flags

        let mcu = "cortex-m7"
        let fpu = ["-mfloat-abi=hard", "-mfpu=fpv5-sp-d16", "-D__FPU_USED=1"]
        let mcFlags = ["-mthumb", "-mcpu=\(mcu)"] + fpu

        let gccIncludePaths = [
            "/include",
            "/include-fixed",
            "/../../../../arm-none-eabi/include"
        ].map { "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/lib/gcc/arm-none-eabi/9.2.1" + $0 }

        let cFlags = gccIncludePaths.flatMap { ["-I", $0] }

        let swiftFlags = cFlags.flatMap { ["-Xcc", $0] } + [
            "-Osize",
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
            "-module-alias", "PlaydateKit=playdatekit_device"
        ]

        let cFlagsSimulator: [String] = []

        let swiftFlagsSimulator = cFlagsSimulator.flatMap { ["-Xcc", $0] } + [
            "-module-alias", "PlaydateKit=playdatekit_simulator"
        ]

        // MARK: - CLI

        @Sendable func cc(_ arguments: [String]) throws {
            let process = Process()
            process.executableURL = URL(filePath: arm_none_eabi_gcc)
            process.arguments = ["-g3"] + arguments
            if verbose { process.print() }
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { throw Error.ccFailed(exitCode: process.terminationStatus) }
        }

        @Sendable func swiftc(_ arguments: [String]) throws {
            let xcrun = try context.tool(named: "xcrun")
            let process = Process()
            process.executableURL = URL(filePath: xcrun.path.string)
            process.arguments = ["-f", "swiftc", "--toolchain", swiftToolchain]
            let pipe = Pipe()
            process.standardOutput = pipe
            if verbose { process.print() }
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { throw Error.xcrunFailed(exitCode: process.terminationStatus) }
            let swiftc = try String(decoding: pipe.fileHandleForReading.readToEnd() ?? Data(), as: UTF8.self)
                .trimmingCharacters(in: .newlines)
            let process2 = Process()
            process2.executableURL = URL(filePath: swiftc)
            process2.arguments = arguments
            if verbose { process2.print() }
            try process2.run()
            process2.waitUntilExit()
            guard process2.terminationStatus == 0 else { throw Error.swiftcFailed(exitCode: process2.terminationStatus) }
        }

        @Sendable func clang(_ arguments: [String]) throws {
            let clang = try context.tool(named: "clang")
            let process = Process()
            var environment = ProcessInfo.processInfo.environment

            environment["TVOS_DEPLOYMENT_TARGET"] = nil
            environment["DRIVERKIT_DEPLOYMENT_TARGET"] = nil
            environment["MACOSX_DEPLOYMENT_TARGET"] = nil
            environment["WATCHOS_DEPLOYMENT_TARGET"] = nil
            environment["XROS_DEPLOYMENT_TARGET"] = nil
            environment["IPHONEOS_DEPLOYMENT_TARGET"] = nil

            process.environment = environment
            process.executableURL = URL(filePath: clang.path.string)
            process.arguments = /* ["-g"] + */ arguments
            if verbose { process.print() }
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { throw Error.clangFailed(exitCode: process.terminationStatus) }
        }

        func pdc(_ arguments: [String]) throws {
            let process = Process()
            process.executableURL = URL(filePath: "\(playdateSDK)/bin/pdc")
            process.arguments = arguments
            if verbose { process.print() }
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { throw Error.pdcFailed(exitCode: process.terminationStatus) }
        }

        // MARK: - Build

        // setup.o
        let setup = context.pluginWorkDirectory.appending(["setup.o"]).string
        try cc(mcFlags + [
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

        async let buildDevice: () = Task {
            // playdatekit_device.o
            print("building playdatekit_device.o")
            try swiftc(swiftFlags + swiftFlagsDevice + ["-c"] + playdateKitSwiftFiles + [
                "-emit-module", "-o", playdateKitDevicePath.string
            ])

            // $(productName)_device.o
            print("building \(productDevicePath.lastComponent)")
            try swiftc(swiftFlags + swiftFlagsDevice + ["-c"] + productSwiftFiles + [
                "-o", productDevicePath.string
            ])

            print("building pdex.elf")
            try cc([setup, productDevicePath.string] + mcFlags + [
                "-T\(playdateSDK)/C_API/buildsupport/link_map.ld",
                "-Wl,-Map=\(context.pluginWorkDirectory.appending(["pdex.map"]).string),--cref,--gc-sections,--no-warn-mismatch,--emit-relocs",
                "-o", sourcePath.appending(["pdex.elf"]).string
            ])
        }.value

        async let buildSimulator: () = Task {
            // playdatekit_simulator.o
            print("building playdatekit_simulator.o")
            try swiftc(swiftFlags + swiftFlagsSimulator + ["-c"] + playdateKitSwiftFiles + [
                "-emit-module", "-o", playdateKitSimulatorPath.string
            ])

            // $(productName)_simulator.o
            print("building \(productSimulatorPath.lastComponent)")
            try swiftc(swiftFlags + swiftFlagsSimulator + ["-c"] + productSwiftFiles + [
                "-o", productSimulatorPath.string
            ])

            print("building pdex.dylib")
            try clang([
                "-nostdlib", "-dead_strip",
                "-Wl,-exported_symbol,_eventHandlerShim", "-Wl,-exported_symbol,_eventHandler",
                productSimulatorPath.string, "-dynamiclib", "-rdynamic", "-lm",
                "-DTARGET_SIMULATOR=1", "-DTARGET_EXTENSION=1",
                "-I", ".",
                "-I", "\(playdateSDK)/C_API",
                "-o", sourcePath.appending(["pdex.dylib"]).string,
                "\(playdateSDK)/C_API/buildsupport/setup.c"
            ])
        }.value

        _ = try await [buildDevice, buildSimulator]

        print("running pdc")
        try pdc([
            sourcePath.string,
            productPath
        ])
    }

    func swiftToolchain() throws -> String {
        struct Info: Decodable { let CFBundleIdentifier: String }
        let toolchainPath = "Library/Developer/Toolchains/swift-latest.xctoolchain"
        if let toolchain = ProcessInfo.processInfo.environment["TOOLCHAINS"] {
            return toolchain
        } else if FileManager.default.fileExists(atPath: "\(home)\(toolchainPath)"),
                  let data = try? Data(contentsOf: URL(filePath: "\(home)\(toolchainPath)/Info.plist")),
                  let info = try? PropertyListDecoder().decode(Info.self, from: data) {
            return info.CFBundleIdentifier
        } else if FileManager.default.fileExists(atPath: "/\(toolchainPath)"),
                  let data = try? Data(contentsOf: URL(filePath: "/\(toolchainPath)/Info.plist")),
                  let info = try? PropertyListDecoder().decode(Info.self, from: data) {
            return info.CFBundleIdentifier
        }
        throw Error.swiftToolchainNotFound
    }

    func playdateSDK() throws -> String {
        if let sdk = ProcessInfo.processInfo.environment["PLAYDATE_SDK_PATH"],
           FileManager.default.fileExists(atPath: sdk) {
            return sdk
        } else if FileManager.default.fileExists(atPath: "\(home)Developer/PlaydateSDK/") {
            return "\(home)Developer/PlaydateSDK/"
        }
        throw Error.playdateSDKNotFound
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
