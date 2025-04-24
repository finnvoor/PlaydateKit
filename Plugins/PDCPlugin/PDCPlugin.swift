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
    case swift
    case clang(_ publicHeaderSearchPaths: [String], _ searchPaths: [String])
}

// MARK: - ModuleBuildRequest

struct ModuleBuildRequest {
    let name: String
    let type: ModuleType
    let relativeURL: URL
    let sourcefiles: [String]

    func moduleName(for dest: BuildDestination) -> String {
        if case .clang = type {
            "\(name)_\(dest)"
        } else {
            "\(name.lowercased())_\(dest)"
        }
    }

    func moduleFilename(for dest: BuildDestination) -> String {
        let suffix = switch type {
        case .product:
            "o"
        case .swift:
            "swiftmodule"
        case .clang:
            "a"
        }
        if case .clang = type {
            return "lib\(moduleName(for: dest)).\(suffix)"
        } else {
            return "\(moduleName(for: dest)).\(suffix)"
        }
    }

    func modulePath(for dest: BuildDestination) -> String {
        relativeURL.appending(path: moduleFilename(for: dest)).path(percentEncoded: false)
    }

    func moduleObjectsURL(for dest: BuildDestination) -> URL {
        relativeURL.appending(path: "\(moduleName(for: dest))")
    }
}

// MARK: - PDCPlugin

@main struct PDCPlugin: CommandPlugin {
    let home = FileManager.default.homeDirectoryForCurrentUser.path()

    func performCommand(context: PluginContext, arguments: [String]) async throws {
        var arguments = ArgumentExtractor(arguments)
        let verbose = arguments.extractFlag(named: "verbose") > 0
        let clean = arguments.extractFlag(named: "clean") > 0

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
                    $0.name == productNameArg
                })?.sourceModules.first {
                    print("Found product named \(argModule.name).")
                    return argModule
                } else {
                    // If the provided product was not found, error out
                    print("Failed to locate product named \(productNameArg).")
                    throw Error.productNotFound
                }
            }

            // Find the first product that has PlaydateKit as a dependency
            if let searchedModule = context.package.products.first(where: {
                $0.targets.first(where: {
                    $0.recursiveTargetDependencies.first(where: {
                        $0.name.caseInsensitiveCompare("PlaydateKit") == .orderedSame
                    }) != nil
                }) != nil
            })?.sourceModules.first {
                print("Found product named \(searchedModule.name).")
                return searchedModule
            }

            print("Failed to locate a suitable Package product.")
            throw Error.productNotFound
        }

        let productModule: any SourceModuleTarget = try findProductModule()

        // MARK: - Paths

        #if !os(Linux)
        let swiftToolchain = try getSwiftToolchain()
        print("found Swift toolchain: \(swiftToolchain)")
        #endif

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

        let product = ModuleBuildRequest(
            name: productName,
            type: .product,
            relativeURL: context.pluginWorkDirectoryURL,
            sourcefiles: productModule.sourceFiles(withSuffix: "swift").map {
                $0.url.path(percentEncoded: false)
            }
        )
        var _productDependencies: [ModuleBuildRequest] = []

        func appendBuildModuleFrom(_ sourceModule: SourceModuleTarget) {
            switch sourceModule {
            case let sourceModule as ClangSourceModuleTarget:
                var publicHeaderSearchPaths: [String] = []
                for publicHeadersURL in [sourceModule.directoryURL.appending(path: "include")] {
                    var isDirectory: ObjCBool = false
                    if FileManager.default.fileExists(atPath: publicHeadersURL.path(percentEncoded: false), isDirectory: &isDirectory) {
                        if isDirectory.boolValue == true {
                            publicHeaderSearchPaths.append(publicHeadersURL.path(percentEncoded: false))
                        }
                    }
                }
                var headerSearchPaths: [String] = sourceModule.headerSearchPaths
                for headersURL in [sourceModule.directoryURL.appending(path: "src")] {
                    var isDirectory: ObjCBool = false
                    if FileManager.default.fileExists(atPath: headersURL.path(percentEncoded: false), isDirectory: &isDirectory) {
                        if isDirectory.boolValue == true {
                            headerSearchPaths.append(headersURL.path(percentEncoded: false))
                        }
                    }
                }
                var sourceFiles: [String] = sourceModule.sourceFiles(withSuffix: "c").map {
                    $0.url.path(percentEncoded: false)
                }
                sourceFiles.append(contentsOf: sourceModule.sourceFiles(withSuffix: "cpp").map {
                    $0.url.path(percentEncoded: false)
                })
                _productDependencies.append(
                    ModuleBuildRequest(
                        name: sourceModule.name,
                        type: .clang(publicHeaderSearchPaths, headerSearchPaths),
                        relativeURL: modulesURL,
                        sourcefiles: sourceFiles
                    )
                )
            case let sourceModule as SwiftSourceModuleTarget:
                _productDependencies.append(
                    ModuleBuildRequest(
                        name: sourceModule.name,
                        type: .swift,
                        relativeURL: modulesURL,
                        sourcefiles: sourceModule.sourceFiles(withSuffix: "swift").map { $0.url.path(percentEncoded: false) }
                    )
                )
            default:
                // TODO: Mixed source targets comming in future Swift (6.1?)
                fatalError("Unsupported source module type: \(type(of: sourceModule))")
            }
        }
        for dependency in productModule.recursiveTargetDependencies {
            if let sourceModule = dependency.sourceModule {
                appendBuildModuleFrom(sourceModule)
            }
        }

        // Immutable for concurrency
        let productDependencies = _productDependencies

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
            throw Error.armNoneEabiGCCNotFound
        }

        let cFlags = gccIncludePaths
            .flatMap { ["-I", URL(fileURLWithPath: $0).standardized.path] } + [
                "-DSWIFT_STDLIB_ENABLE_UNICODE_DATA=1"
            ]

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
        ]

        func getSwiftModuleAliases(for destination: BuildDestination) -> [String] {
            var moduleAliases: [String] = []
            for module in productDependencies {
                if case .swift = module.type {
                    moduleAliases.append("-module-alias")
                    moduleAliases.append("\(module.name)=\(module.moduleName(for: destination))")
                }
            }
            return moduleAliases
        }

        func getCIncludes(for _: BuildDestination) -> [String] {
            var searchPaths: [String] = []
            for module in productDependencies {
                if case let .clang(publicHeaders, _) = module.type {
                    for path in publicHeaders {
                        searchPaths.append("-I")
                        searchPaths.append(path)
                    }
                }
            }
            return searchPaths
        }

        @Sendable func getLinkedLibraries(for destination: BuildDestination) -> [String] {
            var linkedLibraries: [String] = []
            for module in productDependencies {
                if case let .clang(publicHeaders, _) = module.type {
                    guard module.sourcefiles.isEmpty == false else { continue }
                    for path in publicHeaders {
                        linkedLibraries.append("-l\(module.moduleName(for: destination))")
                    }
                }
            }
            return linkedLibraries
        }

        @Sendable func getLinkedLibraryObjects(for destination: BuildDestination) -> [String] {
            var objectFiles: [String] = []
            for module in productDependencies {
                if case let .clang(publicHeaders, _) = module.type {
                    guard module.sourcefiles.isEmpty == false else { continue }
                    for path in publicHeaders {
                        let url = modulesURL.appending(path: module.moduleName(for: destination))
                        do {
                            let files = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                            for file in files {
                                if file.pathExtension == "o" {
                                    objectFiles.append(file.path(percentEncoded: false))
                                }
                            }
                        } catch {
                            continue
                        }
                    }
                }
            }
            return objectFiles
        }

        let cFlagsDevice = mcFlags + ["-falign-functions=16", "-fshort-enums"]

        let swiftFlagsDevice = cFlagsDevice.flatMap { ["-Xcc", $0] } + [
            "-target", "armv7em-none-none-eabi",
            "-Xfrontend", "-experimental-platform-c-calling-convention=arm_aapcs_vfp",
        ] + getSwiftModuleAliases(for: .device) + getCIncludes(for: .device)

        let cFlagsSimulator: [String] = []

        let swiftFlagsSimulator = cFlagsSimulator.flatMap { ["-Xcc", $0] } + [
            // No manual flags
        ] + getSwiftModuleAliases(for: .simulator) + getCIncludes(for: .simulator)

        // MARK: - CLI

        @Sendable func ccURL() throws -> URL {
            guard let url = [
                "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/bin/arm-none-eabi-gcc",
                try? context.tool(named: "arm-none-eabi-gcc").url.absoluteString
            ].compactMap(\.self).filter({
                FileManager.default.fileExists(atPath: $0)
            }).map({ URL(filePath: $0) }).first else {
                Diagnostics.warning("arm-none-eabi-gcc not found. Ensure it is installed and in the PATH.")
                throw Error.armNoneEabiGCCNotFound
            }
            return url
        }

        @Sendable func clangURL() throws -> URL {
            #if os(macOS)
            let swiftToolchainPath: [String?] = [swiftToolchain.path + "/usr/bin/clang"]
            #else
            let swiftToolchainPath: [String?] = []
            #endif
            guard let url = (swiftToolchainPath + [
                try? context.tool(named: "clang").url.absoluteString
            ]).compactMap(\.self).filter({
                FileManager.default.fileExists(atPath: $0)
            }).map({ URL(filePath: $0) }).first else {
                Diagnostics.warning("clang not found. Ensure it is installed and in the PATH.")
                throw Error.clangNotFound
            }
            return url
        }

        @Sendable func pdcURL() throws -> URL {
            guard let url = try [
                "\(getPlaydateSDK())/bin/pdc",
                try? context.tool(named: "pdc").url.absoluteString
            ].compactMap(\.self).filter({
                FileManager.default.fileExists(atPath: $0)
            }).map({ URL(filePath: $0) }).first else {
                Diagnostics.warning("pdc not found. Ensure the Playdate SDK is installed and the pdc tool is available.")
                throw Error.pdcNotFound
            }
            return url
        }

        @Sendable func cc(_ arguments: [String]) throws {
            let process = Process()
            process.executableURL = try ccURL()
            process.arguments = ["-g3"] + arguments
            if verbose { process.print() }
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { throw Error.ccFailed(exitCode: process.terminationStatus) }
        }

        @Sendable func swiftc(_ arguments: [String]) throws {
            let swiftc: String
            if let xcrun = try? context.tool(named: "xcrun") {
                let process = Process()
                process.executableURL = xcrun.url
                #if !os(Linux)
                process.arguments = ["-f", "swiftc", "--toolchain", swiftToolchain.id]
                #endif
                let pipe = Pipe()
                process.standardOutput = pipe
                if verbose { process.print() }
                try process.run()
                process.waitUntilExit()
                guard process.terminationStatus == 0 else { throw Error.xcrunFailed(exitCode: process.terminationStatus) }
                swiftc = try String(decoding: pipe.fileHandleForReading.readToEnd() ?? Data(), as: UTF8.self)
                    .trimmingCharacters(in: .newlines)
            } else {
                do {
                    swiftc = try context.tool(named: "swiftc").url.absoluteString
                } catch {
                    Diagnostics.warning("swiftc not found. Ensure a Swift Toolchain is installed and available.")
                    throw Error.swiftToolchainNotFound
                }
            }
            let process2 = Process()
            process2.executableURL = URL(filePath: swiftc)
            process2.arguments = ["-g"] + arguments
            if verbose { process2.print() }
            try process2.run()
            process2.waitUntilExit()
            guard process2.terminationStatus == 0 else { throw Error.swiftcFailed(exitCode: process2.terminationStatus) }
        }

        @Sendable func clang(_ arguments: [String]) throws {
            let process = Process()
            var environment = ProcessInfo.processInfo.environment

            environment["TVOS_DEPLOYMENT_TARGET"] = nil
            environment["DRIVERKIT_DEPLOYMENT_TARGET"] = nil
            environment["MACOSX_DEPLOYMENT_TARGET"] = nil
            environment["WATCHOS_DEPLOYMENT_TARGET"] = nil
            environment["XROS_DEPLOYMENT_TARGET"] = nil
            environment["IPHONEOS_DEPLOYMENT_TARGET"] = nil

            process.environment = environment
            process.executableURL = try clangURL()
            process.arguments = ["-g"] + arguments
            if verbose { process.print() }
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { throw Error.clangFailed(exitCode: process.terminationStatus) }
        }

        @Sendable func ar(workingDir: String? = nil, _ arguments: [String]) throws {
            let ar = try context.tool(named: "ar")
            let process = Process()
            process.executableURL = URL(filePath: ar.url.path(percentEncoded: false))
            if let workingDir {
                process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
            }
            process.arguments = arguments
            if verbose { process.print() }
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { throw Error.arFailed(exitCode: process.terminationStatus) }
        }

        @Sendable func ranlib(workingDir: String? = nil, _ arguments: [String]) throws {
            let ar = try context.tool(named: "ranlib")
            let process = Process()
            process.executableURL = URL(filePath: ar.url.path(percentEncoded: false))
            if let workingDir {
                process.currentDirectoryURL = URL(fileURLWithPath: workingDir)
            }
            process.arguments = arguments
            if verbose { process.print() }
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { throw Error.arFailed(exitCode: process.terminationStatus) }
        }

        func pdc(_ arguments: [String]) throws {
            let process = Process()
            process.executableURL = try pdcURL()
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
            let moduleResources = module.sourceFiles.filter { $0.type == .unknown }.map { $0.url.path(percentEncoded: false) }
            for resource in moduleResources {
                // `SourceModuleTarget` has no `directoryURL` as of Swift 6 so we
                // need to cast to each module type to get the directoryURL
                let moduleURL = switch module {
                case let module as SwiftSourceModuleTarget:
                    module.directoryURL
                case let module as ClangSourceModuleTarget:
                    module.directoryURL
                default:
                    fatalError("Unknown module type \(type(of: module))")
                }
                let relativePrefix = moduleURL.appending(path: "Resources").path(percentEncoded: false)
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
                print("creating directory \(relativeDestDirectory.path(percentEncoded: false))")
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
                switch module.type {
                case .product:
                    print("building \(module.moduleName(for: .device)) (pdex.elf)")
                    // $(productName)_device.o
                    try swiftc(swiftFlags + swiftFlagsDevice + module.sourcefiles + [
                        "-c", "-o", module.modulePath(for: .device)
                    ])
                    let ccObjects: [String] = [
                        setup,
                        module.modulePath(for: .device)
                    ] + getLinkedLibraryObjects(for: .device)
                    try cc(ccObjects + mcFlags + [
                        "-T\(playdateSDK)/C_API/buildsupport/link_map.ld",
                        "-Wl,-Map=\(context.pluginWorkDirectoryURL.appending(path: "pdex.map").path(percentEncoded: false)),--cref,--gc-sections,--no-warn-mismatch,--emit-relocs",
                        "-o", sourceURL.appending(path: "pdex.elf").path(percentEncoded: false),
                    ])
                case .swift:
                    print("building \(module.moduleName(for: .device)) (Swift)")
                    try swiftc(swiftFlags + swiftFlagsDevice + module.sourcefiles + [
                        "-module-name", module.moduleName(for: .device), "-emit-module", "-emit-module-path", module.modulePath(for: .device)
                    ])
                case let .clang(publicHeaderSearchPaths, headerSearchPaths):
                    print("building \(module.moduleName(for: .device)) (C/C++)")
                    guard module.sourcefiles.isEmpty == false else { return }
                    let objectsPath = module.moduleObjectsURL(for: .device).path(percentEncoded: false)
                    if FileManager.default.fileExists(atPath: objectsPath) == false {
                        try FileManager.default.createDirectory(atPath: objectsPath, withIntermediateDirectories: true, attributes: nil)
                    }
                    var objectFiles: [String] = []
                    objectFiles.reserveCapacity(module.sourcefiles.count)
                    var headerSearchPathFlags: [String] = []
                    for path in publicHeaderSearchPaths {
                        headerSearchPathFlags.append("-I")
                        headerSearchPathFlags.append(path)
                    }
                    for path in headerSearchPaths {
                        headerSearchPathFlags.append("-I")
                        headerSearchPathFlags.append(path)
                    }
                    for sourceFile in module.sourcefiles {
                        let sourceFileURL = URL(fileURLWithPath: sourceFile)
                        let objectFileURL = module.moduleObjectsURL(for: .device).appending(path: sourceFileURL.deletingPathExtension().appendingPathExtension("o").lastPathComponent)
                        let objectFilePath = objectFileURL.path(percentEncoded: false)
                        try cc(mcFlags + cFlags + headerSearchPathFlags + [
                            "-fno-exceptions",
                            "-c",
                            sourceFileURL.path(percentEncoded: false),
                            "-o",
                            objectFilePath,
                        ])
                        objectFiles.append(objectFilePath)
                    }
                    try ar(["rcs", module.modulePath(for: .device)] + objectFiles)
                    try ranlib([module.modulePath(for: .device)])
                }
            }.value
        }

        @Sendable func buildSimulatorModule(_ module: ModuleBuildRequest) async throws {
            try await Task {
                switch module.type {
                case .product:
                    #if os(Linux)
                    print("building \(module.moduleName(for: .simulator)) (pdex.so)")
                    #else
                    print("building \(module.moduleName(for: .simulator)) (pdex.dylib)")
                    #endif
                    // $(productName)_simulator.o
                    try swiftc(swiftFlags + swiftFlagsSimulator + module.sourcefiles + [
                        "-c", "-o", module.modulePath(for: .simulator)
                    ])
                    #if os(Linux)
                    let linkerFlags = [
                        "-Wl,--undefined=_eventHandlerShim",
                        "-Wl,--undefined=_eventHandler",
                        "-shared",
                        "-o",
                        sourceURL.appending(path: "pdex.so").path(percentEncoded: false)
                    ]
                    try clang(linkerFlags + [
                        "-nostdlib", "-dead_strip",
                        module.modulePath(for: .simulator), "-lc", "-lm",
                        "-DTARGET_SIMULATOR=1", "-DTARGET_EXTENSION=1",
                        "-I", ".",
                        "-I", "\(playdateSDK)/C_API",
                        "-L\(modulesURL.path(percentEncoded: false))"
                    ] + getLinkedLibraries(for: .simulator) + [
                        "\(playdateSDK)/C_API/buildsupport/setup.c",
                    ])
                    #else
                    let linkerFlags = [
                        "-Wl,-exported_symbol,_eventHandlerShim",
                        "-Wl,-exported_symbol,_eventHandler",
                        "-dynamiclib",
                        "-rdynamic",
                        "-o",
                        sourceURL.appending(path: "pdex.dylib").path(percentEncoded: false)
                    ]
                    let macOSSDKPath = try getMacOSSDKPath(context: context)
                    try clang(linkerFlags + [
                        "-nostdlib", "-dead_strip",
                        module.modulePath(for: .simulator), "-lc", "-lm",
                        "-DTARGET_SIMULATOR=1", "-DTARGET_EXTENSION=1",
                        "-I", ".",
                        "-I", "\(playdateSDK)/C_API",
                        "-L\(modulesURL.path(percentEncoded: false))",
                        "-isysroot", macOSSDKPath,
                        "-I", "\(macOSSDKPath)/usr/include"
                    ] + getLinkedLibraries(for: .simulator) + [
                        "\(playdateSDK)/C_API/buildsupport/setup.c",
                    ])
                    #endif
                case .swift:
                    print("building \(module.moduleName(for: .simulator)) (Swift)")
                    try swiftc(swiftFlags + swiftFlagsSimulator + module.sourcefiles + [
                        "-module-name", module.moduleName(for: .simulator), "-emit-module", "-emit-module-path", module.modulePath(for: .simulator)
                    ])
                case let .clang(publicHeaderSearchPaths, headerSearchPaths):
                    print("building \(module.moduleName(for: .simulator)) (C/C++)")
                    guard module.sourcefiles.isEmpty == false else { return }
                    let objectsPath = module.moduleObjectsURL(for: .simulator).path(percentEncoded: false)
                    if FileManager.default.fileExists(atPath: objectsPath) == false {
                        try FileManager.default.createDirectory(atPath: objectsPath, withIntermediateDirectories: true, attributes: nil)
                    }
                    var objectFiles: [String] = []
                    objectFiles.reserveCapacity(module.sourcefiles.count)
                    var headerSearchPathFlags: [String] = []
                    for path in publicHeaderSearchPaths {
                        headerSearchPathFlags.append("-I")
                        headerSearchPathFlags.append(path)
                    }
                    for path in headerSearchPaths {
                        headerSearchPathFlags.append("-I")
                        headerSearchPathFlags.append(path)
                    }
                    for sourceFile in module.sourcefiles {
                        let sourceFileURL = URL(fileURLWithPath: sourceFile)
                        let objectFileURL = module.moduleObjectsURL(for: .simulator).appending(path: sourceFileURL.deletingPathExtension().appendingPathExtension("o").lastPathComponent)
                        let objectFilePath = objectFileURL.path(percentEncoded: false)
                        try clang(headerSearchPathFlags + cFlags + [
                            "-c",
                            "-o",
                            objectFilePath,
                            sourceFileURL.path(percentEncoded: false)
                        ])
                        objectFiles.append(objectFilePath)
                    }
                    try ar(["rcs", module.modulePath(for: .simulator)] + objectFiles)
                }
            }.value
        }

        func removeDebugSymbols() throws {
            print("Removing pdex.dylib.dSYM")
            let url = URL(fileURLWithPath: productPath).appending(path: "pdex.dylib.dSYM")
            if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
                try FileManager.default.removeItem(at: url)
            }
        }

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
        try removeDebugSymbols()

        print("created \(productName).pdx at:")
        print(productPath)
        print("\nbuild succeeded.\n")
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
                    .filter { $0.contains(".xctoolchain") }[0]
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

    #if os(macOS)
    func getMacOSSDKPath(context: PluginContext) throws -> String {
        let xcrun = try context.tool(named: "xcrun")
        let process = Process()
        process.executableURL = xcrun.url
        process.arguments = ["--show-sdk-path"]
        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus == 0,
           let output = try? String(decoding: pipe.fileHandleForReading.readToEnd() ?? Data(), as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines),
           FileManager.default.fileExists(atPath: output) {
            return output
        }

        let commonPaths = [
            "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk",
            "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
        ]

        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        throw Error.macOSSDKNotFound
    }
    #endif
}

// MARK: PDCPlugin.Error

extension PDCPlugin {
    enum Error: Swift.Error {
        case productNotFound
        case swiftToolchainNotFound
        case playdateSDKNotFound
        case armNoneEabiGCCNotFound
        case clangNotFound
        case pdcNotFound
        case ccFailed(exitCode: Int32)
        case xcrunFailed(exitCode: Int32)
        case swiftcFailed(exitCode: Int32)
        case clangFailed(exitCode: Int32)
        case arFailed(exitCode: Int32)
        case pdcFailed(exitCode: Int32)
        case macOSSDKNotFound
    }
}

extension Process {
    func print() {
        Swift.print(([executableURL?.path() ?? ""] + (arguments ?? [])).joined(separator: " "))
    }
}
