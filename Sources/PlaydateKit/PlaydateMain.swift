/// Handles the entry point and setup code
///
/// This macro should only be used exactly once, and the type it's used on
/// should conform to ``PlaydateGame``. A global variable `game` is
/// created to store the game object.
@attached(peer, names: named(game), named(eventHandler))
public macro PlaydateMain() = #externalMacro(module: "PlaydateKitMacros", type: "PlaydateMainMacro")
