// MARK: - GameDelegate

/// A set of methods to manage the lifecycle and events for your game.
public protocol GameDelegate: AnyObject {
    /// Called after loading pdex.bin into memory.
    init()

    /// Implement this callback and Playdate OS will call it once per frame. This is the place to put the main update-and-draw
    /// code for your game. Playdate will attempt to call this function by default 30 times per second; that value can be changed
    /// by changing `Playdate.Display.refreshRate`.
    /// The update function should return true to tell the system to update the display, or false if an update isn’t needed.
    func update() -> Bool

    /// Called before the system pauses the game. (In the current version of Playdate OS, this only happens when the
    /// device’s Menu button is pushed.) Implementing these functions allows your game to take special action when it
    /// is paused, e.g., updating the menu image.
    func willPause()
    /// Called before the system resumes the game.
    func didResume()
    
    /// Called immediatley after internal setup has finished
    func didFinishLaunching()
    /// Called when the player chooses to exit the game via the System Menu or Menu button.
    func willTerminate()
    
    /// Called before the device goes to low-power sleep mode because of a low battery.
    func deviceWillSleep()
    /// If your game is running on the Playdate when the device is locked, this function will be called. Implementing
    /// this function allows your game to take special action when the Playdate is locked, e.g., saving state.
    func deviceWillLock()
    /// If your game is running on the Playdate when the device is unlocked, this function will be called.
    func deviceDidUnlock()
    
    /// Keyboard key changed to down
    /// - parameter keyCode: The host OS keyboard keycode.
    /// - note: Only gets called from Playdate Simulator.
    func keyDown(_ keyCode: UInt32)
    /// Keyboard key changed to up
    /// - parameter keyCode: The host OS keyboard keycode.
    /// - note: Only gets called from Playdate Simulator.
    func keyUp(_ keyCode: UInt32)

    // Created and populated automatically by the @PlaydateMain macro
    static var shared: Self { get }
}

public extension GameDelegate {
    func update() -> Bool { false }

    func didFinishLaunching() {}
    func willTerminate() {}

    func willPause() {}
    func didResume() {}
    
    func deviceWillSleep() {}
    func deviceWillLock() {}
    func deviceDidUnlock() {}
    
    func keyDown(_ keyCode: UInt32) {}
    func keyUp(_ keyCode: UInt32) {}
}

public extension GameDelegate {
    static func _eventHandler(pointer: UnsafeMutableRawPointer!, event: System.Event, arg: UInt32) -> Int32 {
        switch event {
        case .initialize:
            Playdate.initialize(with: pointer)
            System.updateCallback = { () -> Bool in
                return Self.shared.update()
            }
            Self.shared.didFinishLaunching()
        case .initializeLua:
            fatalError("Lua initialization not supported")
        case .lock:
            Self.shared.deviceWillLock()
        case .unlock:
            Self.shared.deviceDidUnlock()
        case .pause:
            Self.shared.willPause()
        case .resume:
            Self.shared.didResume()
        case .terminate:
            Self.shared.willTerminate()
        case .keyPressed:
            Self.shared.keyDown(arg)
        case .keyReleased:
            Self.shared.keyUp(arg)
        case .lowPower:
            Self.shared.deviceWillSleep()
        default:
            return 0
        }
        return 1
    }
}
