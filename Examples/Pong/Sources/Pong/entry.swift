import PlaydateKit

/// Boilerplate entry code
nonisolated(unsafe) var game: Game!
@_cdecl("eventHandler") func eventHandler(
    pointer: UnsafeMutablePointer<PlaydateAPI>!,
    event: System.Event,
    arg _: CUnsignedInt
) -> CInt {
    switch event {
    case .initialize:
        Playdate.initialize(with: pointer)
        game = Game()
        System.updateCallback = game.update
    default: game.handle(event)
    }
    return 0
}
