import PlaydateKit

/// Boilerplate entry code
nonisolated(unsafe) var game: BasicExample!
@_cdecl("eventHandler") func eventHandler(
    pointer: UnsafeMutableRawPointer!,
    event: Playdate.System.Event,
    _: UInt32
) -> Int32 {
    switch event {
    case .initialize:
        Playdate.initialize(with: pointer)
        game = BasicExample()
        Playdate.System.updateCallback = game.update
    default: game.handle(event)
    }
    return 0
}
