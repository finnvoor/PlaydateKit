import PlaydateKit

/// Boilerplate entry code
nonisolated(unsafe) var game: BasicExample!
@_cdecl("eventHandler") func eventHandler(
    pointer: UnsafeMutableRawPointer!,
    event: System.Event,
    _: CUnsignedInt
) -> CInt {
    switch event {
    case .initialize:
        Playdate.initialize(with: pointer)
        game = BasicExample()
        System.updateCallback = game.update
    default: game.handle(event)
    }
    return 0
}
