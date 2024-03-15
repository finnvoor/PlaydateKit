import PlaydateKit

/// The update function should return true to tell the system to update the display, or false if update isn’t needed.
func update() -> Bool {
    // update loop
    false
}

@_cdecl("eventHandler") func eventHandler(
    pointer: UnsafeMutableRawPointer!,
    event: Playdate.System.Event,
    _: UInt32
) -> Int32 {
    switch event {
    case .initialize:
        Playdate.initialize(with: pointer)
        Playdate.System.updateCallback = update

        Playdate.System.addMenuItem(title: "PlaydateKit") { _ in
            Playdate.System.logToConsole(format: "PlaydateKit selected!")
        }
    default: break
    }
    return 0
}
