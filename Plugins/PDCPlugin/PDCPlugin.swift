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
                --extra-device-o-files-build-dirs <dirs>  Add more built directories to device `.o` files search (comma-separated)
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

    func buildDevice(
        context: PluginContext,
        target: PackagePlugin.Target,
        configuration: PackageManager.BuildConfiguration,
        verbose: Bool,
        extraDeviceOFilesBuildDirs: [String]
    ) throws {
        let deviceParameters = try PackageManager.BuildParameters(
            configuration: configuration,
            logging: verbose ? .verbose : .concise,
            echoLogs: verbose
        ).loadFlags(from: deviceToolset)

        let result = try packageManager.build(
            .target(target.name),
            parameters: deviceParameters
        )

        guard result.succeeded else {
            if !verbose { print(result.logText) }
            throw Error.buildFailed
        }

        var oFiles: [String] = []
        for url in try FileManager.default.contentsOfDirectory(
            at: context.pluginWorkDirectoryURL
                .appending(component: "../../..")
                .appending(component: configuration.rawValue)
                .appending(component: "CPlaydate.build"),
            includingPropertiesForKeys: nil
        ) where url.pathExtension == "o" {
            oFiles.append(url.path(percentEncoded: false))
        }

        for extraDir in extraDeviceOFilesBuildDirs {
            for url in try FileManager.default.contentsOfDirectory(
                at: context.pluginWorkDirectoryURL
                    .appending(component: "../../..")
                    .appending(component: configuration.rawValue)
                    .appending(component: extraDir),
                includingPropertiesForKeys: nil
            ) where url.pathExtension == "o" {
                oFiles.append(url.path(percentEncoded: false))
            }
        }

        for url in try FileManager.default.contentsOfDirectory(
            at: context.pluginWorkDirectoryURL
                .appending(component: "../../..")
                .appending(component: configuration.rawValue)
                .appending(component: "\(target.name).build"),
            includingPropertiesForKeys: nil
        ) where url.pathExtension == "o" {
            oFiles.append(url.path(percentEncoded: false))
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
                context.pluginWorkDirectoryURL
                    .appending(component: "Source")
                    .path(percentEncoded: false),
                context.pluginWorkDirectoryURL
                    .appending(component: product.name)
                    .path(percentEncoded: false),
                "-sdkpath",
                playdateSDKPath,
            ],
            verbose: verbose
        )
    }

    func execute(tool: URL, arguments: [String], verbose: Bool = false) throws {
        let task = Process()
        task.executableURL = tool
        task.arguments = arguments
        task.standardOutput = FileHandle.standardOutput
        task.standardError = FileHandle.standardError
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
    }
}
