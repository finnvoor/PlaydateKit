import Foundation
import PackagePlugin

// MARK: - Tools

struct Tools {
    // MARK: Internal

    let context: PluginContext
    var verbose = false

    func cc(_ arguments: [String]) throws {
        let process = Process()
        process.executableURL = try ccURL()
        process.arguments = ["-g3"] + arguments
        if verbose { process.print() }
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw Error.armNoneEabiGCCFailed(exitCode: process.terminationStatus)
        }
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
        Diagnostics.warning("Swift toolchain not found. Ensure it is installed in /Library/Developer/Toolchains or set in the TOOLCHAINS environment variable.")
        throw Error.swiftToolchainNotFound
    }

    func swiftc(_ arguments: [String]) throws {
        let swiftc: String
        if let xcrun = try? context.tool(named: "xcrun") {
            let process = Process()
            process.executableURL = URL(filePath: xcrun.path.string)
            process.arguments = try ["-f", "swiftc", "--toolchain", swiftToolchain()]
            let pipe = Pipe()
            process.standardOutput = pipe
            if verbose { process.print() }
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                throw Error.xcrunFailed(exitCode: process.terminationStatus)
            }
            swiftc = try String(decoding: pipe.fileHandleForReading.readToEnd() ?? Data(), as: UTF8.self)
                .trimmingCharacters(in: .newlines)
        } else {
            do {
                swiftc = try context.tool(named: "swiftc").path.string
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
        guard process2.terminationStatus == 0 else {
            throw Error.swiftcFailed(exitCode: process2.terminationStatus)
        }
    }

    func clang(_ arguments: [String]) throws {
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
        guard process.terminationStatus == 0 else {
            throw Error.clangFailed(exitCode: process.terminationStatus)
        }
    }

    func playdateSDK() throws -> String {
        if let path = [
            ProcessInfo.processInfo.environment["PLAYDATE_SDK_PATH"],
            "\(home)Developer/PlaydateSDK"
        ].compactMap({ $0 }).filter({
            FileManager.default.fileExists(atPath: $0)
        }).first {
            return path
        }
        Diagnostics.warning("Playdate SDK not found. Ensure it is installed to ~/Developer/PlaydateSDK or set in the PLAYDATE_SDK_PATH environment variable.")
        throw Error.playdateSDKNotFound
    }

    func pdc(_ arguments: [String]) throws {
        let process = Process()
        process.executableURL = try pdcURL()
        process.arguments = ["--skip-unknown"] + arguments
        if verbose { process.print() }
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw Error.pdcFailed(exitCode: process.terminationStatus)
        }
    }

    // MARK: Private

    private let home = FileManager.default.homeDirectoryForCurrentUser.path()

    private func ccURL() throws -> URL {
        guard let url = [
            "/usr/local/playdate/gcc-arm-none-eabi-9-2019-q4-major/bin/arm-none-eabi-gcc",
            try? context.tool(named: "arm-none-eabi-gcc").path.string
        ].compactMap({ $0 }).filter({
            FileManager.default.fileExists(atPath: $0)
        }).map({ URL(filePath: $0) }).first else {
            Diagnostics.warning("arm-none-eabi-gcc not found. Ensure it is installed and in the PATH.")
            throw Error.armNoneEabiGCCNotFound
        }
        return url
    }

    private func clangURL() throws -> URL {
        guard let url = [
            try? context.tool(named: "clang").path.string
        ].compactMap({ $0 }).filter({
            FileManager.default.fileExists(atPath: $0)
        }).map({ URL(filePath: $0) }).first else {
            Diagnostics.warning("clang not found. Ensure it is installed and in the PATH.")
            throw Error.clangNotFound
        }
        return url
    }

    private func pdcURL() throws -> URL {
        guard let url = try [
            "\(playdateSDK())/bin/pdc",
            try? context.tool(named: "pdc").path.string
        ].compactMap({ $0 }).filter({
            FileManager.default.fileExists(atPath: $0)
        }).map({ URL(filePath: $0) }).first else {
            Diagnostics.warning("pdc not found. Ensure the Playdate SDK is installed and the pdc tool is available.")
            throw Error.pdcNotFound
        }
        return url
    }
}

// MARK: Tools.Error

extension Tools {
    enum Error: Swift.Error {
        case swiftToolchainNotFound
        case playdateSDKNotFound
        case pdcNotFound
        case armNoneEabiGCCNotFound
        case clangNotFound
        case armNoneEabiGCCFailed(exitCode: Int32)
        case xcrunFailed(exitCode: Int32)
        case swiftcFailed(exitCode: Int32)
        case clangFailed(exitCode: Int32)
        case pdcFailed(exitCode: Int32)
    }
}
