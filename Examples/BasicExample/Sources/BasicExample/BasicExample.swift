import PlaydateKit

final class BasicExample: PlaydateGame {
    init() {
        Playdate.System.addMenuItem(title: "PlaydateKit") { _ in
            Playdate.System.logToConsole(format: "PlaydateKit selected!")
        }
    }

    func update() -> Bool {
        Playdate.System.drawFPS(x: 0, y: 0)
        return true
    }

    func gameWillPause() {
        Playdate.System.logToConsole(format: "Paused!")
    }
}

// Boilerplate entry code
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
    default:
        game.handle(event)
    }
    return 0
}
