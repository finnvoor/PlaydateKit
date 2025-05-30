import Foundation
import PackagePlugin

// MARK: - RenamePlugin

@main struct RenamePlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let arguments = Arguments(arguments)

        guard !arguments.hasFlag(named: "help") else {
            print("""
            OVERVIEW: Rename a PlaydateKit Swift package.

            USAGE: swift package rename --from <old-name> --to <new-name>

            OPTIONS:
            -f, --from <old-name>           The current name of the package to rename.
            -t, --to <new-name>             The new name for the package.
            """)
            return
        }

        guard let oldName = arguments.value(for: "from"),
              let newName = arguments.value(for: "to") else {
            print("⚠ Missing required arguments `--from` and `--to`")
            throw Error.missingRequiredArguments
        }

        guard oldName.range(of: "[^a-zA-Z0-9_]", options: .regularExpression) == nil,
              newName.range(of: "[^a-zA-Z0-9_]", options: .regularExpression) == nil else {
            print("⚠ Package names must not contain special characters.")
            throw Error.noSpecialCharacters
        }

        try FileManager.default.moveItem(
            at: context.package.directoryURL
                .appendingPathComponent("Sources")
                .appendingPathComponent(oldName),
            to: context.package.directoryURL
                .appendingPathComponent("Sources")
                .appendingPathComponent(newName)
        )

        let oldXCSchemeURL = context.package.directoryURL
            .appendingPathComponent(".swiftpm")
            .appendingPathComponent("xcode")
            .appendingPathComponent("xcshareddata")
            .appendingPathComponent("xcschemes")
            .appendingPathComponent(oldName)
            .appendingPathExtension("xcscheme")

        let newXCSchemeURL = context.package.directoryURL
            .appendingPathComponent(".swiftpm")
            .appendingPathComponent("xcode")
            .appendingPathComponent("xcshareddata")
            .appendingPathComponent("xcschemes")
            .appendingPathComponent(newName)
            .appendingPathExtension("xcscheme")

        try FileManager.default.moveItem(
            at: oldXCSchemeURL,
            to: newXCSchemeURL
        )

        let packageSwiftURL = context.package.directoryURL
            .appendingPathComponent("Package.swift")
        var packageSwiftContent = try String(contentsOf: packageSwiftURL, encoding: .utf8)
        packageSwiftContent.replace("\"\(oldName)\"", with: "\"\(newName)\"")
        try packageSwiftContent.write(to: packageSwiftURL, atomically: false, encoding: .utf8)

        var xcSchemeContent = try String(contentsOf: newXCSchemeURL, encoding: .utf8)
        xcSchemeContent.replace("\"\(oldName)\"", with: "\"\(newName)\"")
        try xcSchemeContent.write(to: newXCSchemeURL, atomically: false, encoding: .utf8)

        print("✔ Rename complete!")
    }
}

// MARK: RenamePlugin.Error

extension RenamePlugin {
    enum Error: Swift.Error {
        case missingRequiredArguments
        case noSpecialCharacters
    }
}
