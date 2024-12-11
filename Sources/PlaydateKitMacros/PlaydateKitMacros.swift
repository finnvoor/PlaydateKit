import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct PlaydateKitMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        PlaydateMainMacro.self,
    ]
}
