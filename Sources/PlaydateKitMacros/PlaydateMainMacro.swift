import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxMacros

struct MyError: Error, CustomStringConvertible {
	var description: String {
		"@PlaydateMain should only be used on a struct, class, or enum declaration"
	}
}

struct PlaydateMainMacro: PeerMacro {
	static func expansion(
		of attribute: AttributeSyntax,
		providingPeersOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		let gameType: TokenSyntax
		if let classDecl = declaration.as(ClassDeclSyntax.self) {
			gameType = classDecl.name.trimmed
		} else if let structDecl = declaration.as(StructDeclSyntax.self) {
			gameType = structDecl.name.trimmed
		} else if let enumDecl = declaration.as(EnumDeclSyntax.self) {
			gameType = enumDecl.name.trimmed
		} else {
			throw MyError()
		}
		
		return [
			"nonisolated(unsafe) fileprivate var game: \(gameType)!",
			"""
			@_cdecl("eventHandler")
			func eventHandler(
				pointer: UnsafeMutablePointer<PlaydateAPI>,
				event: System.Event,
				arg _: CUnsignedInt
			) -> CInt {
				switch event {
					case .initialize:
						Playdate.initialize(with: pointer)
						game = \(gameType)()
						System.updateCallback = game.update
					default:
						game.handle(event)
				}
				
				return 0
			}
			"""
		]
	}
}

@main
struct PlaydateKitPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		PlaydateMainMacro.self
	]
}
