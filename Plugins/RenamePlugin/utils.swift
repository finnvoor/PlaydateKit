import Foundation
import PackagePlugin

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
