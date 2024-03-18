// MARK: - PlaydateGame

public protocol PlaydateGame {
    /// Called after loading pdex.bin into memory.
    init()

    /// Implement this callback and Playdate OS will call it once per frame. This is the place to put the main update-and-draw
    /// code for your game. Playdate will attempt to call this function by default 30 times per second; that value can be changed
    /// by changing `Playdate.Display.refreshRate`.
    /// The update function should return true to tell the system to update the display, or false if an update isn’t needed.
    func update() -> Bool

    /// Called when the player chooses to exit the game via the System Menu or Menu button.
    func gameWillTerminate()
    /// Called before the device goes to low-power sleep mode because of a low battery.
    func deviceWillSleep()
    /// If your game is running on the Playdate when the device is locked, this function will be called. Implementing
    /// this function allows your game to take special action when the Playdate is locked, e.g., saving state.
    func deviceWillLock()
    /// If your game is running on the Playdate when the device is unlocked, this function will be called.
    func deviceDidUnlock()
    /// Called before the system pauses the game. (In the current version of Playdate OS, this only happens when the
    /// device’s Menu button is pushed.) Implementing these functions allows your game to take special action when it
    /// is paused, e.g., updating the menu image.
    func gameWillPause()
    /// Called before the system resumes the game.
    func gameWillResume()
}

public extension PlaydateGame {
    func update() -> Bool { false }

    func gameWillTerminate() {}
    func deviceWillSleep() {}
    func deviceWillLock() {}
    func deviceDidUnlock() {}
    func gameWillPause() {}
    func gameWillResume() {}

    func handle(_ event: Playdate.System.Event) {
        switch event {
        case .lock: deviceWillLock()
        case .unlock: deviceDidUnlock()
        case .pause: gameWillPause()
        case .resume: gameWillResume()
        case .terminate: gameWillTerminate()
        case .lowPower: deviceWillSleep()
        default: break
        }
    }
}
