import Foundation
import PackagePlugin

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
