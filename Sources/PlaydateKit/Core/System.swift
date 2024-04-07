public import CPlaydate

/// Functions related to menu items, peripherals, and input.
public enum System {
    // MARK: Public

    public typealias Event = PDSystemEvent
    public typealias Language = PDLanguage
    public typealias DateTime = PDDateTime
    public typealias Peripherals = PDPeripherals
    public typealias Buttons = PDButtons

    // MARK: - Interacting with the System Menu

    /// A menu item that allows the player to cycle through a set of options.
    ///
    /// To create an OptionsMenuItem, use ``System/addOptionsMenuItem(title:options:callback:)-41irl``.
    public class OptionsMenuItem: MenuItem {
        // MARK: Public

        /// The currently selected option.
        public var selectedOption: CInt {
            get { value }
            set { value = newValue }
        }

        // MARK: Internal

        var optionsCallback: ((CInt) -> Void)?
    }

    /// A menu item that can be checked or unchecked by the player.
    ///
    /// To create a CheckmarkMenuItem, use ``System/addCheckmarkMenuItem(title:isChecked:callback:)-51m33``.
    public class CheckmarkMenuItem: MenuItem {
        // MARK: Public

        /// Whether or not the menu item is checked.
        public var isChecked: Bool {
            get { value != 0 }
            set { value = newValue ? 1 : 0 }
        }

        // MARK: Internal

        var checkmarkCallback: ((Bool) -> Void)?
    }

    /// A menu item that displays a title.
    ///
    /// To create a MenuItem, use ``System/addMenuItem(title:callback:)-dig``.
    public class MenuItem {
        // MARK: Lifecycle

        init(pointer: OpaquePointer) {
            self.pointer = pointer
        }

        // MARK: Public

        /// Gets/sets the title of the menu item.
        public var title: UnsafePointer<CChar> {
            get { system.getMenuItemTitle.unsafelyUnwrapped(pointer).unsafelyUnwrapped }
            set { system.setMenuItemTitle.unsafelyUnwrapped(pointer, newValue) }
        }

        public func setTitle(_ title: StaticString) {
            system.setMenuItemTitle(pointer, title.utf8Start)
        }

        // MARK: Internal

        let pointer: OpaquePointer

        var callback: (() -> Void)?

        /// Gets/sets the value of the menu item.
        ///
        /// For checkmark menu items, 1 means checked, 0 unchecked.
        /// For option menu items, the value indicates the array index of the currently selected option.
        var value: CInt {
            get { system.getMenuItemValue.unsafelyUnwrapped(pointer) }
            set { system.setMenuItemValue.unsafelyUnwrapped(pointer, newValue) }
        }

        /// Gets/sets the userdata value associated with this menu item.
        var userdata: UnsafeMutableRawPointer? {
            get { system.getMenuItemUserdata.unsafelyUnwrapped(pointer) }
            set { system.setMenuItemUserdata.unsafelyUnwrapped(pointer, newValue) }
        }
    }

    /// Returns the last-read accelerometer data.
    public static var accelerometer: (x: Float, y: Float, z: Float) {
        var x: Float = 0, y: Float = 0, z: Float = 0
        system.getAccelerometer.unsafelyUnwrapped(&x, &y, &z)
        return (x, y, z)
    }

    /// `current` reflects which buttons are currently down. `pushed` and `released` reflect which buttons
    /// were pushed or released over the previous update cycle—at the nominal frame rate of 50 ms,
    /// fast button presses can be missed if you just poll the instantaneous state.
    public static var buttonState: (current: PDButtons, pushed: PDButtons, released: PDButtons) {
        var current = PDButtons(rawValue: 0),
            pushed = PDButtons(rawValue: 0),
            released = PDButtons(rawValue: 0)
        system.getButtonState.unsafelyUnwrapped(&current, &pushed, &released)
        return (current, pushed, released)
    }

    /// A custom update function.
    ///
    /// The update function should return true to tell the system to update the display, or false if an update isn’t needed.
    public nonisolated(unsafe) static var updateCallback: (() -> Bool)? = nil

    public private(set) nonisolated(unsafe) static var menuItems: [MenuItem] = []

    // MARK: - Time and Date

    /// Returns the number of milliseconds since…​some arbitrary point in time.
    ///
    /// This should present a consistent timebase while a game is running,
    /// but the counter will be disabled when the device is sleeping.
    public static var currentTimeMilliseconds: CUnsignedInt {
        system.getCurrentTimeMilliseconds.unsafelyUnwrapped()
    }

    /// Returns the number of seconds since `playdate.resetElapsedTime()` was called.
    /// The value is a floating-point number with microsecond accuracy.
    public static var elapsedTime: Float {
        system.getElapsedTime.unsafelyUnwrapped()
    }

    /// Returns the system timezone offset from GMT, in seconds.
    public static var timezoneOffset: CInt {
        system.getTimezoneOffset.unsafelyUnwrapped()
    }

    /// Returns true if the user has set the 24-Hour Time preference in the Settings program.
    public static var shouldDisplay24HourTime: Bool {
        system.shouldDisplay24HourTime.unsafelyUnwrapped() != 0
    }

    // MARK: - Miscellaneous

    /// Returns true if the global "flipped" system setting is set, otherwise false.
    public static var flipped: Bool {
        system.getFlipped.unsafelyUnwrapped() != 0
    }

    /// Returns true if the global "reduce flashing" system setting is set, otherwise false.
    public static var reduceFlashing: Bool {
        system.getReduceFlashing.unsafelyUnwrapped() != 0
    }

    /// Returns a value from 0-100 denoting the current level of battery charge. 0 = empty; 100 = full.
    public static var batteryPercentage: Float {
        system.getBatteryPercentage.unsafelyUnwrapped()
    }

    /// Returns the battery’s current voltage level.
    public static var batteryVoltage: Float {
        system.getBatteryVoltage.unsafelyUnwrapped()
    }

    /// Returns the current position of the crank, in the range 0-360. Zero is pointing up, and the
    /// value increases as the crank moves clockwise, as viewed from the right side of the device.
    public static var crankAngle: Float {
        system.getCrankAngle.unsafelyUnwrapped()
    }

    /// Returns the angle change of the crank since the last time this function was called.
    /// Negative values are anti-clockwise.
    public static var crankChange: Float {
        system.getCrankChange.unsafelyUnwrapped()
    }

    /// Returns true or false indicating whether or not the crank is folded into the unit.
    public static var isCrankDocked: Bool {
        system.isCrankDocked.unsafelyUnwrapped() != 0
    }

    /// Returns the current language of the system.
    public static var language: Language {
        system.getLanguage.unsafelyUnwrapped()
    }

    /// The accelerometer is off by default, to save a bit of power. If you will be using the accelerometer in your game,
    /// you’ll first need to call `startAccelerometer()` then wait for the next update cycle before reading its values.
    /// If you won’t be using the accelerometer again for a while, calling `stopAccelerometer()` will put it back into a
    /// low-power idle state. (Though, to be honest, the accelerometer draws so little power
    /// when it’s running you’d never notice the difference.)
    public nonisolated(unsafe) static var accelerometerIsEnabled = false {
        didSet {
            if accelerometerIsEnabled {
                system.setPeripheralsEnabled.unsafelyUnwrapped(.accelerometer)
            } else {
                system.setPeripheralsEnabled.unsafelyUnwrapped(.none)
            }
        }
    }

    /// Returns the number of seconds elapsed since midnight (hour 0), January 1, 2000.
    public static var secondsSinceEpoch: CUnsignedInt {
        system.getSecondsSinceEpoch.unsafelyUnwrapped(nil)
    }

    /// Returns the number of milliseconds elapsed since midnight (hour 0), January 1, 2000.
    public static var millisecondsSinceEpoch: CUnsignedInt {
        var ms: CUnsignedInt = 0
        _ = system.getSecondsSinceEpoch.unsafelyUnwrapped(&ms)
        return ms
    }

    // MARK: - Memory allocation

    /// Allocates heap space if `pointer` is nil, else reallocates the given pointer. If `size` is zero, frees the given pointer.
    @discardableResult public static func realloc(
        pointer: UnsafeMutableRawPointer?,
        size: Int
    ) -> UnsafeMutableRawPointer? {
        system.realloc.unsafelyUnwrapped(pointer, size)
    }

    // MARK: - Logging

    /// Calls the log function, outputting an error in red to the console, then pauses execution.
    public static func error(_ error: StaticString) {
        let logError = unsafeBitCast(
            system.error.unsafelyUnwrapped,
            to: (@convention(c) (UnsafePointer<CChar>?) -> Void).self
        )
        error.utf8Start.withMemoryRebound(
            to: CChar.self,
            capacity: error.utf8CodeUnitCount + 1
        ) { pointer in
            logError(pointer)
        }
    }

    /// Calls the log function, outputting an error in red to the console, then pauses execution.
    public static func error(_ error: UnsafePointer<CChar>?) {
        let logError = unsafeBitCast(
            system.error.unsafelyUnwrapped,
            to: (@convention(c) (UnsafePointer<CChar>?) -> Void).self
        )
        logError(error)
    }

    /// Calls the log function, outputting an error in red to the console, then pauses execution.
    public static func error(_ error: Playdate.Error) {
        System.error(error.humanReadableText)
    }

    /// Calls the log function.
    public static func log(_ log: StaticString) {
        let logToConsole = unsafeBitCast(
            system.logToConsole.unsafelyUnwrapped,
            to: (@convention(c) (UnsafePointer<CChar>?) -> Void).self
        )
        log.utf8Start.withMemoryRebound(
            to: CChar.self,
            capacity: log.utf8CodeUnitCount + 1
        ) { pointer in
            logToConsole(pointer)
        }
    }

    /// Calls the log function.
    public static func log(_ log: UnsafePointer<CChar>) {
        let logToConsole = unsafeBitCast(
            system.logToConsole.unsafelyUnwrapped,
            to: (@convention(c) (UnsafePointer<CChar>?) -> Void).self
        )
        logToConsole(log)
    }

    // TODO: - Log/error format string + args

    /// Adds a new menu item to the System Menu.
    /// - Parameters:
    ///   - title: The title displayed by the menu item.
    ///   - callback: The callback invoked when the menu item is selected by the user.
    /// - Returns: The menu item
    @discardableResult public static func addMenuItem(
        title: StaticString,
        callback: (() -> Void)? = nil
    ) -> MenuItem {
        let pointer = system.addMenuItem(title.utf8Start, { userdata in
            let menuItem = unsafeBitCast(userdata, to: MenuItem.self)
            menuItem.callback?()
        }, nil).unsafelyUnwrapped
        let menuItem = MenuItem(pointer: pointer)
        menuItem.callback = callback
        menuItem.userdata = unsafeBitCast(menuItem, to: UnsafeMutableRawPointer.self)
        menuItems.append(menuItem)
        return menuItem
    }

    /// Adds a new menu item to the System Menu.
    /// - Parameters:
    ///   - title: The title displayed by the menu item.
    ///   - callback: The callback invoked when the menu item is selected by the user.
    /// - Returns: The menu item
    @discardableResult public static func addMenuItem(
        title: UnsafePointer<CChar>,
        callback: (() -> Void)? = nil
    ) -> MenuItem {
        let pointer = system.addMenuItem.unsafelyUnwrapped(
            title,
            { userdata in
                let menuItem = unsafeBitCast(userdata, to: MenuItem.self)
                menuItem.callback?()
            },
            nil
        ).unsafelyUnwrapped
        let menuItem = MenuItem(pointer: pointer)
        menuItem.callback = callback
        menuItem.userdata = unsafeBitCast(menuItem, to: UnsafeMutableRawPointer.self)
        menuItems.append(menuItem)
        return menuItem
    }

    /// Adds a new menu item that can be checked or unchecked by the player.
    /// - Parameters:
    ///   - title: The title displayed by the menu item.
    ///   - isChecked: Whether or not the menu item is checked.
    ///   - callback: The callback invoked when the menu item is selected by the user.
    /// - Returns: The menu item
    @discardableResult public static func addCheckmarkMenuItem(
        title: StaticString,
        isChecked: Bool = false,
        callback: ((_ isChecked: Bool) -> Void)? = nil
    ) -> CheckmarkMenuItem {
        let pointer = system.addCheckmarkMenuItem(
            title.utf8Start,
            isChecked ? 1 : 0,
            { userdata in
                let menuItem = unsafeBitCast(userdata, to: CheckmarkMenuItem.self)
                menuItem.checkmarkCallback?(menuItem.isChecked)
            },
            nil
        ).unsafelyUnwrapped
        let menuItem = CheckmarkMenuItem(pointer: pointer)
        menuItem.checkmarkCallback = callback
        menuItem.userdata = unsafeBitCast(menuItem, to: UnsafeMutableRawPointer.self)
        menuItems.append(menuItem)
        return menuItem
    }

    /// Adds a new menu item that can be checked or unchecked by the player.
    /// - Parameters:
    ///   - title: The title displayed by the menu item.
    ///   - isChecked: Whether or not the menu item is checked.
    ///   - callback: The callback invoked when the menu item is selected by the user.
    /// - Returns: The menu item
    @discardableResult public static func addCheckmarkMenuItem(
        title: UnsafePointer<CChar>,
        isChecked: Bool = false,
        callback: ((_ isChecked: Bool) -> Void)? = nil
    ) -> CheckmarkMenuItem {
        let pointer = system.addCheckmarkMenuItem.unsafelyUnwrapped(
            title,
            isChecked ? 1 : 0,
            { userdata in
                let menuItem = unsafeBitCast(userdata, to: CheckmarkMenuItem.self)
                menuItem.checkmarkCallback?(menuItem.isChecked)
            },
            nil
        ).unsafelyUnwrapped
        let menuItem = CheckmarkMenuItem(pointer: pointer)
        menuItem.checkmarkCallback = callback
        menuItem.userdata = unsafeBitCast(menuItem, to: UnsafeMutableRawPointer.self)
        menuItems.append(menuItem)
        return menuItem
    }

    /// Adds a new menu item that allows the player to cycle through a set of options.
    /// - Parameters:
    ///   - title: The title displayed by the menu item.
    ///   - options: An array of strings representing the states this menu item can cycle through. Due to limited horizontal space,
    ///              the option strings and title should be kept short for this type of menu item.
    ///   - callback: The callback invoked when the menu item is selected by the user.
    /// - Returns: The menu item
    @discardableResult public static func addOptionsMenuItem(
        title: StaticString,
        options: [StaticString],
        callback: ((CInt) -> Void)? = nil
    ) -> OptionsMenuItem {
        var options = options.map {
            Optional(UnsafeRawPointer($0.utf8Start).assumingMemoryBound(to: CChar.self))
        }
        let pointer = system.addOptionsMenuItem(
            title.utf8Start,
            &options,
            CInt(options.count),
            { userdata in
                let menuItem = unsafeBitCast(userdata, to: OptionsMenuItem.self)
                menuItem.optionsCallback?(menuItem.selectedOption)
            },
            nil
        ).unsafelyUnwrapped
        let menuItem = OptionsMenuItem(pointer: pointer)
        menuItem.optionsCallback = callback
        menuItem.userdata = unsafeBitCast(menuItem, to: UnsafeMutableRawPointer.self)
        menuItems.append(menuItem)
        return menuItem
    }

    /// Adds a new menu item that allows the player to cycle through a set of options.
    /// - Parameters:
    ///   - title: The title displayed by the menu item.
    ///   - options: An array of strings representing the states this menu item can cycle through. Due to limited horizontal space,
    ///              the option strings and title should be kept short for this type of menu item.
    ///   - callback: The callback invoked when the menu item is selected by the user.
    /// - Returns: The menu item
    @discardableResult public static func addOptionsMenuItem(
        title: UnsafePointer<CChar>,
        options: UnsafeMutableBufferPointer<UnsafePointer<CChar>?>,
        callback: ((CInt) -> Void)? = nil
    ) -> OptionsMenuItem {
        let pointer = system.addOptionsMenuItem.unsafelyUnwrapped(
            title,
            options.baseAddress,
            CInt(options.count),
            { userdata in
                let menuItem = unsafeBitCast(userdata, to: OptionsMenuItem.self)
                menuItem.optionsCallback?(menuItem.selectedOption)
            },
            nil
        ).unsafelyUnwrapped
        let menuItem = OptionsMenuItem(pointer: pointer)
        menuItem.optionsCallback = callback
        menuItem.userdata = unsafeBitCast(menuItem, to: UnsafeMutableRawPointer.self)
        menuItems.append(menuItem)
        return menuItem
    }

    /// Removes the menu item from the system menu.
    public static func removeMenuItem(_ menuItem: MenuItem) {
        system.removeMenuItem.unsafelyUnwrapped(menuItem.pointer)
        menuItems.removeAll(where: { $0.pointer == menuItem.pointer })
    }

    /// Removes all custom menu items from the system menu.
    public static func removeAllMenuItems() {
        system.removeAllMenuItems.unsafelyUnwrapped()
        menuItems = []
    }

    /// Resets the high-resolution timer.
    public static func resetElapsedTime() {
        system.resetElapsedTime.unsafelyUnwrapped()
    }

    /// Converts the given epoch time to a DateTime.
    public static func convertEpochToDateTime(_ epoch: CUnsignedInt) -> DateTime {
        var dateTime = DateTime()
        system.convertEpochToDateTime.unsafelyUnwrapped(epoch, &dateTime)
        return dateTime
    }

    /// Converts the given PDDateTime to an epoch time.
    public static func convertDateTimeToEpoch(_ dateTime: DateTime) -> CUnsignedInt {
        var dateTime = dateTime
        return system.convertDateTimeToEpoch.unsafelyUnwrapped(&dateTime)
    }

    // TODO: - Figure out how to implement these
//        public static func formatString() {}
//        public static func vaFormatString() {}
//        public static func parseString() {}

    /// Sets the menu image.
    ///
    /// A game can optionally provide an image to be displayed alongside the system menu.
    /// bitmap must be a 400x240 LCDBitmap. All important content should be in the left half of the image in an area 200 pixels wide,
    /// as the menu will obscure the rest. The right side of the image will be visible briefly as the menu animates in and out.
    ///
    /// Optionally, a non-zero xoffset, can be provided. This must be a number between 0 and 200 and will cause the menu image
    /// to animate to a position offset left by xoffset pixels as the menu is animated in.
    ///
    /// This function could be called in response to the kEventPause event in your implementation of eventHandler().
    public static func setMenuImage(_ bitmap: Graphics.Bitmap, xOffset: CInt = 0) {
        system.setMenuImage.unsafelyUnwrapped(bitmap.pointer, xOffset)
    }

    /// Provides a callback to receive messages sent to the device over the serial port using the msg command.
    ///
    /// If no device is connected, you can send these messages to a game in the simulator by entering
    /// `!msg <message>` in the Lua console.
    public static func setSerialMessageCallback(
        callback: @convention(c) (_ message: UnsafePointer<CChar>?) -> Void
    ) {
        system.setSerialMessageCallback.unsafelyUnwrapped(callback)
    }

    /// Calculates the current frames per second and draws that value at `point`.
    public static func drawFPS(at point: Point<CInt> = .zero) {
        system.drawFPS.unsafelyUnwrapped(point.x, point.y)
    }

    /// Flush the CPU instruction cache, on the very unlikely chance you’re modifying instruction code on the fly.
    /// (If you don’t know what I’m talking about, you don’t need this. :smile:)
    public static func clearICache() {
        system.clearICache.unsafelyUnwrapped()
    }

    /// Disables or enables the 3 minute auto lock feature. When called, the timer is reset to 3 minutes.
    public static func setAutoLockDisabled(_ disabled: Bool) {
        system.setAutoLockDisabled.unsafelyUnwrapped(disabled ? 1 : 0)
    }

    /// The function returns the previous value for this setting.
    public static func setCrankSoundsDisabled(_ disabled: Bool) -> Bool {
        system.setCrankSoundsDisabled.unsafelyUnwrapped(disabled ? 1 : 0) != 0
    }

    /// As an alternative to polling for button presses using getButtonState(), this function allows a callback function to be set.
    /// The function is called for each button up/down event (possibly multiple events on the same button) that occurred during
    /// the previous update cycle. At the default 30 FPS, a queue size of 5 should be adequate. At lower frame rates/longer frame times,
    /// the queue size should be extended until all button presses are caught. The function should return true on success or false
    /// to signal an error.
    public static func setButtonCallback(
        callback: ((
            _ button: Buttons,
            _ down: Bool,
            _ when: CUnsignedInt,
            _ userdata: UnsafeMutableRawPointer?
        ) -> Bool)?,
        buttonUserdata: UnsafeMutableRawPointer? = nil,
        queueSize: CInt = 5
    ) {
        buttonCallback = callback
        if callback != nil {
            system.setButtonCallback.unsafelyUnwrapped({ button, down, when, userdata in
                (System.buttonCallback?(button, down != 0, when, userdata) ?? false) ? 0 : 1
            }, buttonUserdata, queueSize)
        } else {
            system.setButtonCallback.unsafelyUnwrapped(nil, buttonUserdata, queueSize)
        }
    }

    // MARK: Internal

    /// Replaces the default Lua run loop function with a custom update function.
    ///
    /// The update function should return a non-zero number to tell the system to update the display, or zero if update isn’t needed.
    static func setUpdateCallback(
        update: (@convention(c) (_ userdata: UnsafeMutableRawPointer?) -> CInt)?,
        userdata: UnsafeMutableRawPointer? = nil
    ) {
        system.setUpdateCallback.unsafelyUnwrapped(update, userdata)
    }

    // MARK: Private

    private nonisolated(unsafe) static var buttonCallback: ((
        _ button: Buttons,
        _ down: Bool,
        _ when: CUnsignedInt,
        _ userdata: UnsafeMutableRawPointer?
    ) -> Bool)?

    private static var system: playdate_sys { Playdate.playdateAPI.system.pointee }
}
