import Foundation
import PackagePlugin

// MARK: - PDCPlugin

@main struct PDCPlugin: CommandPlugin {
    let home = FileManager.default.homeDirectoryForCurrentUser.path()

    let deviceToolset = URL(filePath: #filePath)
        .appending(path: "../../../Toolsets/toolset_device.json")
        .standardized

    #if os(Linux)
    let simulatorToolset = URL(filePath: #filePath)
        .appending(path: "../../../Toolsets/toolset_simulator_linux.json")
        .standardized
    #else
    let simulatorToolset = URL(filePath: #filePath)
        .appending(path: "../../../Toolsets/toolset_simulator_macos.json")
        .standardized
    #endif

    var playdateSDKPath: String {
        get throws {
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

    var armToolchainPath: String {
        if let path = ProcessInfo.processInfo.environment["ARM_NONE_EABI_GCC_PATH"] {
            return path
        }
        #if os(Linux)
        return "/usr/lib/gcc/arm-none-eabi/10.3.1"
        #else
        return "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/lib/gcc/arm-none-eabi/9.2.1"
        #endif
    }

    var armSysrootPath: String {
        if let path = ProcessInfo.processInfo.environment["ARM_NONE_EABI_SYSROOT_PATH"] {
            return path
        }
        #if os(Linux)
        return "/usr/lib/arm-none-eabi"
        #else
        return "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/arm-none-eabi"
        #endif
    }

    var playdateSDKURL: URL { get throws { try URL(filePath: playdateSDKPath) } }

    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let arguments = Arguments(arguments)

        guard !arguments.hasFlag(named: "help") else {
            print("""
            OVERVIEW: Build a Swift package into a Playdate executable.

            USAGE: swift package pdc [options]

            OPTIONS:
            -p, --product <product>                       Build the specified product
                --device-only                             Build a device-only executable suitable for distribution
                --simulator-only                          Build a simulator-only executable for quick testing
                --extra-device-o-files-build-dirs <dirs>  Link the device objects of more targets, e.g. `CLodePNG.build` (comma-separated)
            -v, --verbose                                 Increase verbosity to include informational output
            """)
            return
        }

        let startTime = Date()

        let verbose = arguments.hasFlag(named: "verbose")
        let productName = arguments.value(for: "product")
        let deviceOnly = arguments.hasFlag(named: "device-only", allowShort: false)
        let simulatorOnly = arguments.hasFlag(named: "simulator-only", allowShort: false)
        let extraDeviceOFilesBuildDirs = arguments.value(for: "extra-device-o-files-build-dirs", allowShort: false)

        let product: PackagePlugin.Product? = if let productName {
            context.package.products.first {
                $0.name.localizedCaseInsensitiveCompare(productName) == .orderedSame
            }
        } else {
            context.package.products.first
        }

        guard let product else { throw Error.productNotFound }
        guard let target = product.targets.first else { throw Error.targetNotFound }
        if product.targets.count > 1 {
            print("Warning: Multiple targets found in product, using the first one.")
        }

        let pdcBuildDirectory = context.pluginWorkDirectoryURL
            .appending(component: "Source")
        if FileManager.default.fileExists(atPath: pdcBuildDirectory.path(percentEncoded: false)) {
            try FileManager.default.removeItem(at: pdcBuildDirectory)
        }
        try FileManager.default.createDirectory(at: pdcBuildDirectory, withIntermediateDirectories: true)

        if !simulatorOnly {
            print("Building for device...")
            try buildDevice(
                context: context,
                target: target,
                configuration: .release,
                verbose: verbose,
                extraDeviceOFilesBuildDirs: extraDeviceOFilesBuildDirs?.split(separator: ",").map(String.init) ?? []
            )
        }

        if !deviceOnly {
            print("Building for simulator...")
            try buildSimulator(
                context: context,
                product: product,
                configuration: .debug,
                verbose: verbose
            )
        }

        print("Copying resources...")
        try copyResources(
            context: context,
            target: target,
            verbose: verbose
        )

        print("Compiling into pdx...")
        try pdc(
            context: context,
            product: product,
            verbose: verbose
        )

        let buildDuration = (Date().timeIntervalSince(startTime))
            .formatted(.number.precision(.fractionLength(2)))
        let outputPath = context.pluginWorkDirectoryURL
            .appending(component: product.name)
            .appendingPathExtension("pdx")
            .path(percentEncoded: false)

        print("✔ Build complete! (\(buildDuration)s)")
        print(outputPath)
    }

    /// Builds the device objects with a nested `swift build`, since a command plugin can't change the build
    /// triple. Without the `armv7em-none-none-eabi` triple, the `swiftbuild` build system prelinks every target
    /// with the host linker, which can't read the device's ELF objects.
    func buildDevice(
        context: PluginContext,
        target: PackagePlugin.Target,
        configuration: PackageManager.BuildConfiguration,
        verbose: Bool,
        extraDeviceOFilesBuildDirs: [String]
    ) throws {
        let fileManager = FileManager.default
        let scratchDirectory = context.pluginWorkDirectoryURL.appending(component: "../../..").standardized
        let deviceBuildDirectory = context.pluginWorkDirectoryURL.appending(component: "DeviceBuild")
        try fileManager.createDirectory(at: deviceBuildDirectory, withIntermediateDirectories: true)

        // Plugins can't access the network, so seed the nested build with the already resolved dependencies.
        for item in ["workspace-state.json", "checkouts", "repositories", "artifacts"] {
            let source = scratchDirectory.appending(component: item)
            let destination = deviceBuildDirectory.appending(component: item)
            if fileManager.fileExists(atPath: destination.path(percentEncoded: false)) {
                try fileManager.removeItem(at: destination)
            }
            if fileManager.fileExists(atPath: source.path(percentEncoded: false)) {
                try fileManager.copyItem(at: source, to: destination)
            }
        }

        let toolset = deviceBuildDirectory.appending(component: "toolset.json")
        try writeDeviceToolset(to: toolset, linker: context.tool(named: "ld.lld").url)

        let buildArguments = [
            "--package-path", context.package.directoryURL.path(percentEncoded: false),
            "--scratch-path", deviceBuildDirectory.path(percentEncoded: false),
            "--configuration", configuration.rawValue,
            "--triple", "armv7em-none-none-eabi",
            "--toolset", toolset.path(percentEncoded: false),
            "--build-system", "swiftbuild",
            "--disable-automatic-resolution"
        ]
        let swift = try context.tool(named: "swift").url
        let log = deviceBuildDirectory.appending(component: "build.log")
        do {
            try execute(
                tool: swift,
                arguments: ["build", "--target", target.name] + buildArguments + (verbose ? ["--verbose"] : []),
                verbose: verbose,
                output: verbose ? nil : log
            )
        } catch {
            if !verbose { print((try? String(contentsOf: log, encoding: .utf8)) ?? "") }
            throw Error.buildFailed
        }

        let binPathFile = deviceBuildDirectory.appending(component: "bin-path.txt")
        try execute(tool: swift, arguments: ["build", "--show-bin-path"] + buildArguments, output: binPathFile)
        let binDirectory = try URL(
            filePath: String(contentsOf: binPathFile, encoding: .utf8).split(separator: "\n").last.map(String.init) ?? "",
            directoryHint: .isDirectory
        )

        // Every target is prelinked into a single relocatable object named after the target.
        let objectTargets = ["CPlaydate", target.name] + extraDeviceOFilesBuildDirs.map {
            $0.hasSuffix(".build") ? String($0.dropLast(".build".count)) : $0
        }
        let oFiles = objectTargets.map {
            binDirectory.appending(component: "\($0).o").path(percentEncoded: false)
        }

        try execute(tool: context.tool(named: "arm-none-eabi-gcc").url, arguments: oFiles + [
            "-mthumb",
            "-mcpu=cortex-m7",
            "-mfloat-abi=hard",
            "-mfpu=fpv5-sp-d16",
            "-D__FPU_USED=1",
            "-T\(playdateSDKPath)/C_API/buildsupport/link_map.ld",
            "-o", context.pluginWorkDirectoryURL
                .appending(component: "Source")
                .appending(component: "pdex.elf")
                .path(percentEncoded: false),
            "-Wl,--gc-sections,--no-warn-mismatch,--emit-relocs"
        ])
    }

    /// Writes the device toolset extended with the ARM toolchain includes and `ld.lld` as linker, which the
    /// nested build uses to prelink targets.
    func writeDeviceToolset(to url: URL, linker: URL) throws {
        let armIncludes = [
            "-I", "\(armToolchainPath)/include",
            "-I", "\(armToolchainPath)/include-fixed",
            "-I", "\(armSysrootPath)/include"
        ]
        guard var toolset = try JSONSerialization.jsonObject(
            with: Data(contentsOf: deviceToolset)
        ) as? [String: Any] else { throw Error.invalidToolset }
        // Unlike the native build system, swiftbuild doesn't forward C flags to swiftc. Without
        // -fPIC, Swift code addresses globals with MOVW/MOVT relocations, which the Playdate
        // loader doesn't relocate, crashing the game on device.
        let cFlags = (toolset["cCompiler"] as? [String: Any])?["extraCLIOptions"] as? [String] ?? []
        let cOptions = ["-fPIC"] + armIncludes
        for (name, options) in [("cCompiler", cOptions), ("swiftCompiler", (cFlags + cOptions).flatMap { ["-Xcc", $0] })] {
            var tool = toolset[name] as? [String: Any] ?? [:]
            tool["extraCLIOptions"] = (tool["extraCLIOptions"] as? [String] ?? []) + options
            toolset[name] = tool
        }
        var linkerTool = toolset["linker"] as? [String: Any] ?? [:]
        linkerTool["path"] = linker.path(percentEncoded: false)
        toolset["linker"] = linkerTool
        try JSONSerialization.data(withJSONObject: toolset, options: [.prettyPrinted, .sortedKeys]).write(to: url)
    }

    func buildSimulator(
        context: PluginContext,
        product: PackagePlugin.Product,
        configuration: PackageManager.BuildConfiguration,
        verbose: Bool
    ) throws {
        let simulatorParameters = try PackageManager.BuildParameters(
            configuration: configuration,
            logging: verbose ? .verbose : .concise,
            echoLogs: verbose
        ).loadFlags(from: simulatorToolset)

        let result = try packageManager.build(
            .product(product.name),
            parameters: simulatorParameters
        )

        guard result.succeeded else {
            if !verbose { print(result.logText) }
            throw Error.buildFailed
        }

        guard let artifact = result.builtArtifacts.first else { throw Error.missingBuildArtifact }

        try FileManager.default.copyItem(
            at: artifact.url,
            to: context.pluginWorkDirectoryURL
                .appending(component: "Source")
                .appending(component: "pdex")
                .appendingPathExtension(artifact.url.pathExtension)
        )
    }

    func copyResources(
        context: PluginContext,
        target: PackagePlugin.Target,
        verbose: Bool
    ) throws {
        let modules = ([target.sourceModule] + target.recursiveTargetDependencies.map(\.sourceModule))
            .compactMap(\.self)
        var resources: Set<String> = []
        for module in modules {
            let resourcesURL = module.directoryURL.appending(component: "Resources")
            if FileManager.default.fileExists(atPath: resourcesURL.path(percentEncoded: false)) {
                for url in try FileManager.default.contentsOfDirectory(
                    at: resourcesURL,
                    includingPropertiesForKeys: nil
                ) {
                    let relativePath = url.path(percentEncoded: false)
                        .trimmingPrefix(module.directoryURL.appending(component: "Resources").path(percentEncoded: false))
                    if verbose {
                        if url.hasDirectoryPath {
                            print("Copying resources: \(module.name)/Resources\(relativePath)")
                        } else {
                            print("Copying resource: \(module.name)/Resources\(relativePath)")
                        }
                    }
                    guard resources.insert(String(relativePath)).inserted else {
                        throw Error.duplicateResource
                    }
                    try FileManager.default.copyItem(
                        at: url,
                        to: context.pluginWorkDirectoryURL
                            .appending(component: "Source")
                            .appending(component: relativePath)
                    )
                }
            }
        }
    }

    func pdc(
        context: PluginContext,
        product: PackagePlugin.Product,
        verbose: Bool
    ) throws {
        try execute(
            tool: playdateSDKURL
                .appending(component: "bin")
                .appending(component: "pdc"),
            arguments: [
                "-sdkpath",
                playdateSDKPath,
                context.pluginWorkDirectoryURL
                    .appending(component: "Source")
                    .path(percentEncoded: false),
                context.pluginWorkDirectoryURL
                    .appending(component: product.name)
                    .path(percentEncoded: false)
            ],
            verbose: verbose
        )
    }

    /// Runs `tool`, writing its output to `output` if given, or to the standard output otherwise.
    func execute(tool: URL, arguments: [String], verbose: Bool = false, output: URL? = nil) throws {
        let task = Process()
        task.executableURL = tool
        task.arguments = arguments
        if let output {
            FileManager.default.createFile(atPath: output.path(percentEncoded: false), contents: nil)
            let handle = try FileHandle(forWritingTo: output)
            task.standardOutput = handle
            task.standardError = handle
        } else {
            task.standardOutput = FileHandle.standardOutput
            task.standardError = FileHandle.standardError
        }
        if verbose { task.print() }
        try task.run()
        task.waitUntilExit()
        guard task.terminationReason == .exit, task.terminationStatus == 0 else {
            throw Error.unexpectedStatus(reason: task.terminationReason, status: task.terminationStatus)
        }
    }
}

// MARK: PDCPlugin.Error

extension PDCPlugin {
    enum Error: Swift.Error {
        case unknownConfiguration
        case productNotFound
        case targetNotFound
        case playdateSDKNotFound
        case unexpectedStatus(reason: Process.TerminationReason, status: Int32)
        case missingBuildArtifact
        case duplicateResource
        case buildFailed
        case invalidToolset
    }
}
