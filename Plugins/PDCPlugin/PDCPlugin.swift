import Foundation
@preconcurrency import PackagePlugin

// MARK: - BuildDestination

enum BuildDestination {
    case simulator
    case device
}

// MARK: - ModuleType

enum ModuleType {
    case product
    case dependency
}

// MARK: - ModuleBuildRequest

struct ModuleBuildRequest {
    let name: String
    let language: Language
    let type: ModuleType
    let relativeURL: URL
    let sourcefiles: [String]
    
    enum Language {
        case swift
        case c
        case cpp
    }

    func moduleName(for dest: BuildDestination) -> String { "\(name.lowercased())_\(dest)" }

    func modulePath(for dest: BuildDestination) -> String {
        let suffix = switch type {
        case .product: "o"
        default: "swiftmodule"
        }
        return relativeURL.appending(path: "\(moduleName(for: dest)).\(suffix)").path(percentEncoded: false)
    }
}

// MARK: - PDCPlugin

@main struct PDCPlugin: CommandPlugin {
    let home = FileManager.default.homeDirectoryForCurrentUser.path()
    let arm_none_eabi_gcc = "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/bin/arm-none-eabi-gcc"

    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var arguments = ArgumentExtractor(arguments)
        let verbose = arguments.extractFlag(named: "verbose") > 0
        let clean = arguments.extractFlag(named: "clean") > 0
        let disableSwiftUnicodeDataTables = true//arguments.extractFlag(named: "disableSwiftUnicodeDataTables") > 0
        
        if clean {
            let items = try FileManager.default.contentsOfDirectory(atPath: context.pluginWorkDirectoryURL.path(percentEncoded: false))
            for item in items {
                try FileManager.default.removeItem(atPath: context.pluginWorkDirectoryURL.appendingPathComponent(item).path(percentEncoded: false))
            }
        }
        
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
            // TODO: Scan deps recursively in case PlaydateKit is part of an engine
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

        let swiftToolchain = try getSwiftToolchain()
        print("found Swift toolchain: \(swiftToolchain.id)")

        let playdateSDK = try getPlaydateSDK()
        let playdateSDKVersion = (try? String(
            contentsOf: URL(filePath: playdateSDK).appending(path: "VERSION.txt"),
            encoding: .utf8
        ))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "???"
        print("found Playdate SDK (\(playdateSDKVersion))")

        let productName = productModule.name

        let moduleCacheURL = context.pluginWorkDirectoryURL.appending(path: "module-cache")
        let modulesURL = context.pluginWorkDirectoryURL.appending(path: "Modules")

        let sourceURL = context.pluginWorkDirectoryURL.appending(path: "\(productName)-Source")
        let productPath: String = if let targetBuildDir = ProcessInfo.processInfo.environment["TARGET_BUILD_DIR"] {
            // Run from Xcode
            targetBuildDir + "/\(productName).pdx"
        } else {
            context.pluginWorkDirectoryURL.appending(path: "\(productName).pdx").path(percentEncoded: false)
        }

        // MARK: - Source files

        let playdateKitPackage = context.package.dependencies.first(where: { $0.package.id == "playdatekit" })!
        let playdateKitSource = playdateKitPackage.package.sourceModules.first(where: { $0.name == "PlaydateKit" })!
        let playdateKitSwiftFiles = playdateKitSource.sourceFiles(withSuffix: "swift").map({$0.url.path(percentEncoded: false)})
        let cPlaydateInclude = URL(filePath:
            playdateKitPackage.package.sourceModules
            .first(where: { $0.name == "CPlaydate" })!
            .directory.string
        ).appending(path: "include")

        let productSource = productModule
        let productSwiftFiles = productSource.sourceFiles(withSuffix: "swift").map({$0.url.path(percentEncoded: false)})

        let playdateKit = ModuleBuildRequest(name: "playdatekit", language: .swift, type: .dependency, relativeURL: modulesURL, sourcefiles: playdateKitSwiftFiles)
        let product = ModuleBuildRequest(name: productName, language: .swift, type: .product, relativeURL: context.pluginWorkDirectoryURL, sourcefiles: productSwiftFiles)
//        let dependencies = productModule.dependencies.m context.package.dependencies.compactMap { dep -> ModuleBuildRequest? in
//            guard dep.package.id != "playdatekit" else { return nil }
//            let sourceModule = dep.package.sourceModules.first!
//            let sourceFiles = sourceModule.sourceFiles(withSuffix: "swift").map(\.path.string)
//            return ModuleBuildRequest(name: sourceModule.name, type: .dependency, relativePath: modulesPath, sourcefiles: sourceFiles)
//        }
        
        var dependencies: [ModuleBuildRequest] = []
        
        func appendBuildModuleFrom(_ sourceModule: SourceModuleTarget) {
            var language: ModuleBuildRequest.Language = .swift
            let sourceFileList: FileList = {
                let cSourceFiles = sourceModule.sourceFiles(withSuffix: "c")
                if cSourceFiles.isEmpty == false {
                    language = .c
                    return cSourceFiles
                }
                let cppSourceFiles = sourceModule.sourceFiles(withSuffix: "cpp")
                if cppSourceFiles.isEmpty == false {
                    language = .cpp
                    return cppSourceFiles
                }
                return sourceModule.sourceFiles(withSuffix: "swift")
            }()
            guard sourceFileList.isEmpty == false else { return }
            let sourceFiles = sourceFileList.map({$0.url.path(percentEncoded: false)})
            dependencies.append(
                ModuleBuildRequest(
                    name: sourceModule.name,
                    language: language,
                    type: .dependency, 
                    relativeURL: modulesURL,
                    sourcefiles: sourceFiles
                )
            )
        }
        for dependency in productModule.recursiveTargetDependencies {
            if let sourceModule = dependency.sourceModule {
                appendBuildModuleFrom(sourceModule)
            }
        }
        
        let productDependencies = dependencies
        
        print("Products:", productDependencies.map(\.name))

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
            "-module-cache-path", moduleCacheURL.path(percentEncoded: false),
            "-I", "\(playdateSDK)/C_API",
            "-I", modulesURL.path(percentEncoded: false),
            "-I", cPlaydateInclude.path(percentEncoded: false)
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

        if FileManager.default.fileExists(atPath: sourceURL.path(percentEncoded: false)) {
            try FileManager.default.removeItem(
                atPath: sourceURL.path(percentEncoded: false)
            )
        }
        try FileManager.default.createDirectory(
            atPath: sourceURL.path(percentEncoded: false),
            withIntermediateDirectories: true
        )

        print("copying resources...")
        // Create a list of resources including the relative path
        var resourcePaths: [(path: String, relativePath: String)] = []

        // Scan package and dependencies for resources
        func appendResources(for module: any SourceModuleTarget) {
            let moduleResources = module.sourceFiles.filter { $0.type == .unknown }.map({$0.url.path(percentEncoded: false)})
            for resource in moduleResources {
                let relativePrefix = URL(filePath: module.directory.string)
                    .appending(path: "Resources")
                    .path(percentEncoded: false)
                // Only copy resource from the Package's "Resources" directory
                guard resource.hasPrefix(relativePrefix) else { continue }
                let relativePath = resource.replacingOccurrences(of: relativePrefix, with: "")
                resourcePaths.append((resource, relativePath))
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
            let dest = sourceURL.appending(path: resource.relativePath)
            let destDirectory = dest.deletingLastPathComponent()

            if FileManager.default.fileExists(atPath: destDirectory.path(percentEncoded: false), isDirectory: nil) == false {
                let relativeDestDirectory = URL(fileURLWithPath: resource.relativePath).deletingLastPathComponent()
                print("creating directory \(relativeDestDirectory.path(percentEncoded: false))/")
                try FileManager.default.createDirectory(atPath: destDirectory.path(percentEncoded: false), withIntermediateDirectories: true)
            }

            // If the resource is pdxinfo, always place it in the pdx root
            var destination = dest.path(percentEncoded: false)
            if resource.path.hasSuffix("/pdxinfo") {
                destination = sourceURL.appending(path: "pdxinfo").path(percentEncoded: false)
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
                    try cc(ccObjects + mcFlags + [
                        "-T\(playdateSDK)/C_API/buildsupport/link_map.ld",
                        "-Wl,-Map=\(context.pluginWorkDirectoryURL.appending(path: "pdex.map").path(percentEncoded: false)),--cref,--gc-sections,--no-warn-mismatch,--emit-relocs",
                        "-o", sourceURL.appending(path: "pdex.elf").path(percentEncoded: false),
                    ])
                case .dependency:
                    switch module.language {
                    case .swift:
                        try swiftc(swiftFlags + swiftFlagsDevice + module.sourcefiles + [
                            "-module-name", module.moduleName(for: .device), "-emit-module", "-emit-module-path", module.modulePath(for: .device)
                        ])
                    case .c, .cpp:
                        try clang([
                            
                        ])
                    }
                }
            }.value
        }

        @Sendable func buildSimulatorModule(_ module: ModuleBuildRequest) async throws {
            print("building \(module.moduleName(for: .simulator))")
            try await Task {
                switch module.type {
                case .product:
                    // $(productName)_simulator.o
                    let linkedModules = productDependencies.map { ["-module-alias", "\($0.name)=\($0.moduleName(for: .simulator))"] }.flatMap { $0 }
                    try swiftc(swiftFlags + swiftFlagsSimulator + linkedModules + module.sourcefiles + [
                        "-c", "-o", module.modulePath(for: .simulator)
                    ])
                    print("building pdex.dylib")
                    try clang([
                        "-nostdlib", "-dead_strip",
                        "-Wl,-exported_symbol,_eventHandlerShim", "-Wl,-exported_symbol,_eventHandler",
                        module.modulePath(for: .simulator), "-dynamiclib", "-rdynamic", "-lm",
                        "-DTARGET_SIMULATOR=1", "-DTARGET_EXTENSION=1",
                        "-I", ".",
                        "-I", "\(playdateSDK)/C_API",
                        "-o", sourceURL.appending(path: "pdex.dylib").path(percentEncoded: false),
                        "\(playdateSDK)/C_API/buildsupport/setup.c",
                    ])
                case .dependency:
                    try swiftc(swiftFlags + swiftFlagsSimulator + module.sourcefiles + [
                        "-module-name", module.moduleName(for: .simulator), "-emit-module", "-emit-module-path", module.modulePath(for: .simulator)
                    ])
                }
            }.value
        }

//        try await build(module: playdateKit)
        for dep in productDependencies {
            try await build(module: dep)
        }
        try await build(module: product)

        print("\nrunning pdc")
        try pdc([
            sourceURL.path(percentEncoded: false),
            productPath,
            "--version",
            "-sdkpath", playdateSDK,
            "--quiet",
        ])
        
        print("\ncreated \(productName).pdx at:")
        print(productPath)
        print("\nbuild succeeded.")
    }

    func getSwiftToolchain() throws -> (id: String, path: String) {
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

    func getPlaydateSDK() throws -> String {
        if let sdk = ProcessInfo.processInfo.environment["PLAYDATE_SDK_PATH"],
           FileManager.default.fileExists(atPath: sdk) {
            return sdk
        }
        if FileManager.default.fileExists(atPath: "\(home)Developer/PlaydateSDK/") {
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
