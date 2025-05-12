import Foundation
import PackagePlugin

// MARK: - PDCPlugin

@main struct PDCPlugin: CommandPlugin {
    let home = FileManager.default.homeDirectoryForCurrentUser.path()

    let deviceToolset = URL(filePath: #filePath)
        .appending(path: "../../../Toolsets/toolset_device.json")
        .standardized

    let simulatorToolset = URL(filePath: #filePath)
        .appending(path: "../../../Toolsets/toolset_simulator.json")
        .standardized

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

    var gccPath: String {
        "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/bin/arm-none-eabi-gcc"
    }

    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let arguments = Arguments(arguments)

        guard !arguments.hasFlag(named: "help") else {
            print("""
            OVERVIEW: Build sources into a Playdate bundle.

            USAGE: swift package pdc [options]

            OPTIONS:
            -p, --product <product>         Build the specified product
            -c, --configuration <config>    Build with configuration (values: debug, release)
            -v, --verbose                   Increase verbosity to include informational output
            """)
            return
        }

        let verbose = arguments.hasFlag(named: "verbose")
        let productName = arguments.value(for: "product")
        let configurationName = arguments.value(for: "configuration")

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

        let configuration: PackageManager.BuildConfiguration
        if let configurationName {
            guard let configurationValue = PackageManager.BuildConfiguration(
                rawValue: configurationName.lowercased()
            ) else {
                throw Error.unknownConfiguration
            }
            configuration = configurationValue
        } else {
            configuration = .debug
        }

        let pdcBuildDirectory = context.pluginWorkDirectoryURL
            .appending(component: configuration.rawValue)
            .appending(component: "Source")
        if FileManager.default.fileExists(atPath: pdcBuildDirectory.path(percentEncoded: false)) {
            try FileManager.default.removeItem(at: pdcBuildDirectory)
        }
        try FileManager.default.createDirectory(at: pdcBuildDirectory, withIntermediateDirectories: true)

        try buildDevice(
            context: context,
            target: target,
            configuration: configuration,
            verbose: verbose
        )

        if configuration != .release {
            try buildSimulator(
                context: context,
                product: product,
                configuration: configuration,
                verbose: verbose
            )
        }

        try copyResources(
            context: context,
            target: target,
            configuration: configuration,
            verbose: verbose
        )

        try pdc(
            context: context,
            product: product,
            configuration: configuration,
            verbose: verbose
        )
    }

    func buildDevice(
        context: PluginContext,
        target: PackagePlugin.Target,
        configuration: PackageManager.BuildConfiguration,
        verbose: Bool
    ) throws {
        let deviceParameters = try PackageManager.BuildParameters(
            configuration: configuration,
            logging: verbose ? .verbose : .concise,
            echoLogs: true
        ).loadFlags(from: deviceToolset)

        _ = try packageManager.build(
            .target(target.name),
            parameters: deviceParameters
        )

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
        for url in try FileManager.default.contentsOfDirectory(
            at: context.pluginWorkDirectoryURL
                .appending(component: "../../..")
                .appending(component: configuration.rawValue)
                .appending(component: "\(target.name).build"),
            includingPropertiesForKeys: nil
        ) where url.pathExtension == "o" {
            oFiles.append(url.path(percentEncoded: false))
        }

        try execute(tool: URL(filePath: gccPath), arguments: oFiles + [
            "-mthumb",
            "-mcpu=cortex-m7",
            "-mfloat-abi=hard",
            "-mfpu=fpv5-sp-d16",
            "-D__FPU_USED=1",
            "-T\(playdateSDKPath)/C_API/buildsupport/link_map.ld",
            "-o", context.pluginWorkDirectoryURL
                .appending(component: configuration.rawValue)
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
            echoLogs: true
        ).loadFlags(from: simulatorToolset)

        let simulatorResult = try packageManager.build(
            .product(product.name),
            parameters: simulatorParameters
        )

        guard let dylib = simulatorResult.builtArtifacts.first else { throw Error.missingDylib }

        try FileManager.default.copyItem(
            at: dylib.url,
            to: context.pluginWorkDirectoryURL
                .appending(component: configuration.rawValue)
                .appending(component: "Source")
                .appending(component: "pdex.dylib")
        )
    }

    func copyResources(
        context: PluginContext,
        target: PackagePlugin.Target,
        configuration: PackageManager.BuildConfiguration,
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
                            .appending(component: configuration.rawValue)
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
        configuration: PackageManager.BuildConfiguration,
        verbose: Bool
    ) throws {
        try execute(
            tool: context.tool(named: "pdc").url,
            arguments: [
                context.pluginWorkDirectoryURL
                    .appending(component: configuration.rawValue)
                    .appending(component: "Source")
                    .path(percentEncoded: false),
                context.pluginWorkDirectoryURL
                    .appending(component: configuration.rawValue)
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
        case missingDylib
        case duplicateResource
    }
}

extension PackageManager.BuildParameters {
    func loadFlags(from toolset: URL) throws -> PackageManager.BuildParameters {
        struct Toolset: Decodable {
            struct Flags: Decodable {
                let extraCLIOptions: [String]
            }

            let swiftCompiler: Flags?
            let cCompiler: Flags?
            let cxxCompiler: Flags?
            let linker: Flags?
        }
        let toolset = try JSONDecoder().decode(Toolset.self, from: Data(contentsOf: toolset))
        var parameters = self
        parameters.otherSwiftcFlags = toolset.swiftCompiler?.extraCLIOptions ?? []
        parameters.otherCFlags = toolset.cCompiler?.extraCLIOptions ?? []
        parameters.otherCxxFlags = toolset.cxxCompiler?.extraCLIOptions ?? []
        parameters.otherLinkerFlags = toolset.linker?.extraCLIOptions ?? []
        return parameters
    }
}

extension Process {
    func print() {
        Swift.print(([executableURL?.path(percentEncoded: false) ?? ""] + (arguments ?? [])).joined(separator: " "))
    }
}

// MARK: - Arguments

struct Arguments {
    // MARK: Lifecycle

    init(_ arguments: [String]) {
        self.arguments = arguments
    }

    // MARK: Internal

    let arguments: [String]

    func hasFlag(named name: String, allowShort: Bool = true) -> Bool {
        guard !name.isEmpty else { return false }
        return arguments.contains {
            [allowShort ? "-\(name.first!)" : "", "--\(name)"].contains($0)
        }
    }

    func value(for option: String, allowShort: Bool = true) -> String? {
        guard !option.isEmpty else { return nil }
        return zip(arguments, arguments.dropFirst()).first {
            [allowShort ? "-\(option.first!)" : "", "--\(option)"].contains($0.0)
        }?.1
    }
}
