@freestanding(declaration, names: named(game), named(eventHandler))
public macro playdateEntry(_ game: PlaydateGame.Type) = #externalMacro(
    module: "PlaydateKitMacros",
    type: "PlaydateEntry"
)
