import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum PlaydateMainMacroError: Error, CustomStringConvertible {
    case notClass
    
    public var description: String {
        switch self {
        case .notClass:
            "@PlaydateMain can only be attached to a class."
        default:
            "\(self)"
        }
    }
}

public struct PlaydateMainMacro: PeerMacro, MemberMacro {
    public static func expansion(
      of node: AttributeSyntax,
      providingMembersOf declaration: some DeclGroupSyntax,
      conformingTo protocols: [TypeSyntax],
      in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw PlaydateMainMacroError.notClass
        }
        let className = classDecl.name.trimmed
        return [DeclSyntax(
            "nonisolated(unsafe) static let shared: \(className) = \(className)()"
        )]
    }
    
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw PlaydateMainMacroError.notClass
        }
        let className = classDecl.name.trimmed
        return [DeclSyntax(
"""
@_cdecl(\"eventHandler\")
fileprivate func _eventHandler(pointer: UnsafeMutableRawPointer!, event: System.Event, arg: CUnsignedInt) -> CInt {
    return \(className)._eventHandler(pointer: pointer, event: event, arg: arg)
}
"""
        )]
    }
}
