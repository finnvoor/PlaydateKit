import Foundation
@preconcurrency import PackagePlugin

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
    let home = FileManager.default.homeDirectoryForCurrentUser.path()
    let arm_none_eabi_gcc = "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/bin/arm-none-eabi-gcc"

    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var arguments = ArgumentExtractor(arguments)
        let verbose = arguments.extractFlag(named: "verbose") > 0
        let disableSwiftUnicodeDataTables = arguments.extractFlag(named: "disableSwiftUnicodeDataTables") > 0
        
        func findProductModule() throws -> any SourceModuleTarget {
            // Find the product for the provided argument
            if let productNameArg = arguments.extractOption(named: "product").first {
                if let argModule = context.package.products.first(where: {
                    return $0.name == productNameArg
                })?.sourceModules.first {
                    print("Found product named \(argModule.name).")
                    return argModule
                }else{
                    // If the provided product was not found, error out
                    print("Failed to locate product named \(productNameArg).")
                    throw Error.productNotFound
                }
            }
            // Find the first product most liekly to be a Playdate game
            if let searchedModule = context.package.products.first(where: {
                $0.targets.first(where: {
                    $0.dependencies.first(where: {
                        if case .product(let product) = $0 {
                            return product.name == "PlaydateKit"
                        }
                        return false
                    }) != nil
                }) != nil
            })?.sourceModules.first {
                print("Found product named \(productModule.name).")
                return searchedModule
            }
            
            print("Failed to locate a suitable Package product.")
            throw Error.productNotFound
        }
        
        let productModule: any SourceModuleTarget = try findProductModule()

        
        // MARK: - Paths

        let swiftToolchain = try swiftToolchain()
        print("found Swift toolchain: \(swiftToolchain.id)")

        let playdateSDK = try playdateSDK()
        let playdateSDKVersion = (try? String(
            contentsOf: URL(filePath: playdateSDK).appending(path: "VERSION.txt"),
            encoding: .utf8
        ))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "???"
        print("found Playdate SDK (\(playdateSDKVersion))")

        let productName = productModule.name

        let moduleCachePath = context.pluginWorkDirectory.appending(["module-cache"])
        let modulesPath = context.pluginWorkDirectory.appending(["Modules"])

        let sourcePath = context.pluginWorkDirectory.appending(["\(productName)-Source"])
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

        let productSource = productModule
        let productSwiftFiles = productSource.sourceFiles(withSuffix: "swift").map(\.path.string)

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
        ].map { "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/lib/gcc/arm-none-eabi/9.2.1" + $0 }

        let cFlags = gccIncludePaths.flatMap { ["-I", $0] }

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
            process.executableURL = xcrun.url
            process.arguments = ["-f", "swiftc", "--toolchain", swiftToolchain.id]
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
            process2.arguments = ["-g"] + arguments
            if verbose { process2.print() }
            try process2.run()
            process2.waitUntilExit()
            guard process2.terminationStatus == 0 else { throw Error.swiftcFailed(exitCode: process2.terminationStatus) }
        }

        @Sendable func clang(_ arguments: [String]) throws {
            let clangPath = swiftToolchain.path + "/usr/bin/clang"
            let process = Process()
            var environment = ProcessInfo.processInfo.environment

            environment["TVOS_DEPLOYMENT_TARGET"] = nil
            environment["DRIVERKIT_DEPLOYMENT_TARGET"] = nil
            environment["MACOSX_DEPLOYMENT_TARGET"] = nil
            environment["WATCHOS_DEPLOYMENT_TARGET"] = nil
            environment["XROS_DEPLOYMENT_TARGET"] = nil
            environment["IPHONEOS_DEPLOYMENT_TARGET"] = nil

            process.environment = environment
            process.executableURL = URL(filePath: clangPath)
            process.arguments = ["-g"] + arguments
            if verbose { process.print() }
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { throw Error.clangFailed(exitCode: process.terminationStatus) }
        }
        
        @Sendable func ar(workingDir: String, args arguments: [String]) throws {
            let ar = try context.tool(named: "ar")
            let process = Process()
            process.executableURL = URL(filePath: ar.url.path(percentEncoded: false))
            process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
            process.arguments = arguments
            if verbose { process.print() }
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { throw Error.arFailed(exitCode: process.terminationStatus) }
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
        let setup = context.pluginWorkDirectoryURL.appending(path: "setup.o").path(percentEncoded: false)
        let setupLst = context.pluginWorkDirectoryURL.appending(path: "setup.lst").path(percentEncoded: false)
        try cc(mcFlags + [
            "-c", "-O2", "-falign-functions=16", "-fomit-frame-pointer", "-gdwarf-2", "-Wall", "-Wno-unused", "-Wstrict-prototypes", "-Wno-unknown-pragmas", "-fverbose-asm", "-Wdouble-promotion", "-mword-relocations", "-fno-common", "-ffunction-sections", "-fdata-sections", "-Wa,-ahlms=\(setupLst)", "-DTARGET_PLAYDATE=1", "-DTARGET_EXTENSION=1", "-MD", "-MP", "-MF",
            context.pluginWorkDirectoryURL.appending(path: "setup.o.d").path(percentEncoded: false),
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

        print("copying resources...")
        // Create a list of resources including the relative path
        var resourcePaths: [(path: String, relativePath: String)] = []

        // Scan package and dependencies for resources
        func appendResources(for module: any SourceModuleTarget) {
            let moduleResources = module.sourceFiles.filter { $0.type == .unknown }.map(\.path)
            for resource in moduleResources {
                let relativePrefix = module.directory.string + "/Resources/"
                // Only copy resource from the Package's "Resources" directory
                guard resource.string.hasPrefix(relativePrefix) else { continue }
                let relativePath = resource.string.replacingOccurrences(of: relativePrefix, with: "")
                resourcePaths.append((resource.string, relativePath))
            }
        }

        appendResources(for: productModule)
        for dependency in productModule.dependencies {
            switch dependency {
            case let .product(product):
                for module in product.sourceModules {
                    appendResources(for: module)
                }
            case let .target(target):
                if let module = target.sourceModule {
                    appendResources(for: module)
                }
            default: break
            }
        }

        // Copy resources
        for resource in resourcePaths {
            let dest = sourcePath.appending([resource.relativePath])
            let destDirectory = dest.removingLastComponent()

            if FileManager.default.fileExists(atPath: destDirectory.string, isDirectory: nil) == false {
                let relativeDestDirectory = Path(resource.relativePath).removingLastComponent()
                print("creating directory \(relativeDestDirectory.string)/")
                try FileManager.default.createDirectory(atPath: destDirectory.string, withIntermediateDirectories: true)
            }

            // If the resource is pdxinfo, always place it in the pdx root
            var destination = dest.string
            if resource.path.hasSuffix("/pdxinfo") {
                destination = sourcePath.appending(["pdxinfo"]).string
            }

            print("copying \(resource.relativePath)")
            try FileManager.default.copyItem(
                atPath: resource.path,
                toPath: destination
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
                    try swiftc(swiftFlags + swiftFlagsDevice + module.sourcefiles + [
                        "-module-name", module.moduleName(for: .device), "-emit-module", "-emit-module-path", module.modulePath(for: .device)
                    ])
                case .product:
                    // $(productName)_device.o
                    let linkedModules = productDependencies.map { ["-module-alias", "\($0.name)=\($0.moduleName(for: .device))"] }.flatMap { $0 }
                    try swiftc(swiftFlags + swiftFlagsDevice + linkedModules + module.sourcefiles + [
                        "-c", "-o", module.modulePath(for: .device)
                    ])
                    
                    print("building pdex.elf")
                    var ccObjects: [String] = [
                        setup,
                        module.modulePath(for: .device)
                    ]
                    var ccArgs: [String] = []
                    if disableSwiftUnicodeDataTables == false {
                        // libswiftUnicodeDataTables is in a format the linker won't like 
                        // Disassemble libswiftUnicodeDataTables into object files
                        let tableObjectsPath = context.pluginWorkDirectoryURL.appending(path: "SwiftUnicodeDataTables/armv7em-none-none-eabi/").path(percentEncoded: false)
                        try FileManager.default.createDirectory(atPath: tableObjectsPath, withIntermediateDirectories: true)
                        let lib = "\(swiftToolchain.path)/usr/lib/swift/embedded/armv7em-none-none-eabi/libswiftUnicodeDataTables.a"
                        try ar(workingDir: tableObjectsPath, args: ["x", lib])
                        let libObjFiles = try FileManager.default.contentsOfDirectory(atPath: tableObjectsPath).filter({$0.hasSuffix(".o")})
                        // Add object files to be compiled compiled
                        ccObjects.append(contentsOf: libObjFiles.map({tableObjectsPath + $0}))
                        // Avoid linking `_exit`, `_kill`, and `_getpid` from libswiftUnicodeDataTables 
                        ccArgs.append("--specs=nosys.specs")
                    }
                    ccArgs.append(contentsOf: ccObjects + mcFlags)
                    if disableSwiftUnicodeDataTables == false {
                        // Create a customized link_map that allows ARM.exidx
                        // The SDK default linkmap has these off, but libswiftUnicodeDataTables uses them.
                        let linkMapPath = context.pluginWorkDirectoryURL.appending(path: "link_map.ld").path(percentEncoded: false)
                        var linkMap = try String(contentsOf: URL(fileURLWithPath: "\(playdateSDK)/C_API/buildsupport/link_map.ld"), encoding: .utf8)
                        linkMap = linkMap.components(separatedBy: "/DISCARD/")[0]
                        linkMap += "      .ARM.exidx :\n    {\n            __exidx_start = .;\n            *(.ARM.exidx* .gnu.linkonce.armexidx.*)\n            __exidx_end = .;\n    }\n}"
                        try linkMap.data(using: .utf8)!.write(to: URL(fileURLWithPath: linkMapPath))
                        // Use customized link_map
                        ccArgs.append("-T\(linkMapPath)")
                    }else{
                        // Use the unmodified SDK link_map
                        ccArgs.append("-T\(playdateSDK)/C_API/buildsupport/link_map.ld")
                    }
                    ccArgs.append(contentsOf: [
                        "-Wl,-Map=\(context.pluginWorkDirectoryURL.appending(path: "pdex.map").path(percentEncoded: false)),--cref,--gc-sections,--no-warn-mismatch,--emit-relocs",
                        "-o", sourcePath.appending(["pdex.elf"]).string,
                    ])
                    try cc(ccArgs)
                case .productDependency:
                    try swiftc(swiftFlags + swiftFlagsDevice + module.sourcefiles + [
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
                    try swiftc(swiftFlags + swiftFlagsSimulator + module.sourcefiles + [
                        "-module-name", module.moduleName(for: .simulator), "-emit-module", "-emit-module-path", module.modulePath(for: .simulator)
                    ])
                case .product:
                    // $(productName)_simulator.o
                    let linkedModules = productDependencies.map { ["-module-alias", "\($0.name)=\($0.moduleName(for: .simulator))"] }.flatMap { $0 }
                    try swiftc(swiftFlags + swiftFlagsSimulator + linkedModules + module.sourcefiles + [
                        "-c", "-o", module.modulePath(for: .simulator)
                    ])
                    print("building pdex.dylib")
                    var clangArgs: [String] = [
                        "-nostdlib", "-dead_strip",
                        "-Wl,-exported_symbol,_eventHandlerShim", "-Wl,-exported_symbol,_eventHandler",
                        module.modulePath(for: .simulator), "-dynamiclib", "-rdynamic", "-lm",
                        "-DTARGET_SIMULATOR=1", "-DTARGET_EXTENSION=1",
                        "-I", ".",
                        "-I", "\(playdateSDK)/C_API",
                        "-o", sourcePath.appending(["pdex.dylib"]).string,
                        "\(playdateSDK)/C_API/buildsupport/setup.c",
                    ]
                    if disableSwiftUnicodeDataTables == false {
                        #if arch(arm64) && os(macOS) 
                        let hostTriple = "arm64-apple-macos"
                        #elseif arch(x86_64) && os(macOS)
                        let hostTriple = "x86_64-apple-macos"
                        #elseif arch(x86_64)
                        let hostTriple = "x86_64-unknown-none-elf"
                        #elseif arch(arm64)
                        let hostTriple = "aarch64-none-none-elf"
                        #endif
                        clangArgs.append(contentsOf: [
                            "-L\(swiftToolchain.path)/usr/lib/swift/embedded/\(hostTriple)",
                            "-l", "swiftUnicodeDataTables",
                        ])
                    }
                    try clang(clangArgs)
                case .productDependency:
                    try swiftc(swiftFlags + swiftFlagsSimulator + module.sourcefiles + [
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
        try pdc([
            "-sdkpath", playdateSDK,
            sourcePath.string,
            productPath
        ])
        
        print("\ncreated \(productName).pdx at:")
        print(productPath)
        print("\nbuild succeeded.")
    }

    func swiftToolchain() throws -> (id: String, path: String) {
        struct Info: Decodable { let CFBundleIdentifier: String }
        
        // Explicit toolchain request
        if let toolchain = ProcessInfo.processInfo.environment["TOOLCHAINS"] {
            if let toolchainPath = ProcessInfo.processInfo.environment["TOOLCHAIN_PATH"] {
                return (toolchain, toolchainPath)
            }
        }
        
        // Find the toolchain based on DYLD_LIBRARY_PATH
        if let dyldLibraryPath = ProcessInfo.processInfo.environment["DYLD_LIBRARY_PATH"] {
            if dyldLibraryPath.contains(".xctoolchain") {
                let toolchainPath = dyldLibraryPath
                    .components(separatedBy: ":")
                    .filter({$0.contains(".xctoolchain")})[0]
                    .components(separatedBy: ".xctoolchain")[0] + ".xctoolchain"
                if FileManager.default.fileExists(atPath: "\(toolchainPath)/usr/bin/swift") {
                    if let data = try? Data(contentsOf: URL(filePath: "\(home)\(toolchainPath)/Info.plist")),
                       let info = try? PropertyListDecoder().decode(Info.self, from: data) {
                        return (info.CFBundleIdentifier, toolchainPath)
                    }
                }
            }
        }

        // Find the toolchain based on known common paths
        let toolchainPath = "Library/Developer/Toolchains/swift-latest.xctoolchain"
        if FileManager.default.fileExists(atPath: "\(home)\(toolchainPath)") {
            if let data = try? Data(contentsOf: URL(filePath: "\(home)\(toolchainPath)/Info.plist")) {
                if let info = try? PropertyListDecoder().decode(Info.self, from: data) {
                    return (info.CFBundleIdentifier, "\(home)\(toolchainPath)")
                }
            }
        }
        if FileManager.default.fileExists(atPath: "/\(toolchainPath)") {
            if let data = try? Data(contentsOf: URL(filePath: "/\(toolchainPath)/Info.plist")) {
                if let info = try? PropertyListDecoder().decode(Info.self, from: data) {
                    return (info.CFBundleIdentifier, "/\(toolchainPath)")
                }
            }
        }
        
        // Failed to find a toolchain
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
        case productNotFound
        case swiftToolchainNotFound
        case playdateSDKNotFound
        case ccFailed(exitCode: Int32)
        case xcrunFailed(exitCode: Int32)
        case swiftcFailed(exitCode: Int32)
        case clangFailed(exitCode: Int32)
        case arFailed(exitCode: Int32)
        case pdcFailed(exitCode: Int32)
    }
}

extension Process {
    func print() {
        Swift.print(([executableURL?.path() ?? ""] + (arguments ?? [])).joined(separator: " "))
    }
}
