public import CPlaydate

public extension Playdate {
    enum System {
        // MARK: Public

        /// Returns the last-read accelerometer data.
        public static var accelerometer: (x: Float, y: Float, z: Float) {
            var x: Float = 0, y: Float = 0, z: Float = 0
            system.getAccelerometer(&x, &y, &z)
            return (x, y, z)
        }

        /// `current` reflects which buttons are currently down. `pushed` and `released` reflect which buttons
        /// were pushed or released over the previous update cycle—at the nominal frame rate of 50 ms,
        /// fast button presses can be missed if you just poll the instantaneous state.
        public static var buttonState: (current: PDButtons, pushed: PDButtons, released: PDButtons) {
            var current = PDButtons(rawValue: 0), pushed = PDButtons(rawValue: 0), released = PDButtons(rawValue: 0)
            system.getButtonState(&current, &pushed, &released)
            return (current, pushed, released)
        }

        // MARK: - Time and Date

        /// Returns the number of milliseconds since…​some arbitrary point in time.
        ///
        /// This should present a consistent timebase while a game is running,
        /// but the counter will be disabled when the device is sleeping.
        public static var currentTimeMilliseconds: UInt32 {
            system.getCurrentTimeMilliseconds()
        }

        /// Returns the number of seconds since `playdate.resetElapsedTime()` was called.
        /// The value is a floating-point number with microsecond accuracy.
        public static var elapsedTime: Float {
            system.getElapsedTime()
        }

        /// Returns the system timezone offset from GMT, in seconds.
        public static var timezoneOffset: Int32 {
            system.getTimezoneOffset()
        }

        /// Returns true if the user has set the 24-Hour Time preference in the Settings program.
        public static var shouldDisplay24HourTime: Bool {
            system.shouldDisplay24HourTime() != 0
        }

        // MARK: - Miscellaneous

        /// Returns true if the global "flipped" system setting is set, otherwise false.
        public static var flipped: Bool {
            system.getFlipped() != 0
        }

        /// Returns true if the global "reduce flashing" system setting is set, otherwise false.
        public static var reduceFlashing: Bool {
            system.getReduceFlashing() != 0
        }

        /// Returns a value from 0-100 denoting the current level of battery charge. 0 = empty; 100 = full.
        public static var batteryPercentage: Float {
            system.getBatteryPercentage()
        }

        /// Returns the battery’s current voltage level.
        public static var batteryVoltage: Float {
            system.getBatteryVoltage()
        }

        /// Returns the current position of the crank, in the range 0-360. Zero is pointing up, and the
        /// value increases as the crank moves clockwise, as viewed from the right side of the device.
        public static var crankAngle: Float {
            system.getCrankAngle()
        }

        /// Returns the angle change of the crank since the last time this function was called.
        /// Negative values are anti-clockwise.
        public static var crankChange: Float {
            system.getCrankChange()
        }

        /// Returns true or false indicating whether or not the crank is folded into the unit.
        public static var isCrankDocked: Bool {
            system.isCrankDocked() != 0
        }

        /// Returns the current language of the system.
        public static var language: PDLanguage {
            system.getLanguage()
        }

        // MARK: - Memory allocation

        /// Allocates heap space if `ptr` is NULL, else reallocates the given pointer. If `size` is zero, frees the given pointer.
        public static func realloc(ptr: UnsafeMutableRawPointer?, size: Int) -> UnsafeMutableRawPointer {
            system.realloc(ptr, size).unsafelyUnwrapped
        }

        // MARK: - Logging

        /// Calls the log function, outputting an error in red to the console, then pauses execution.
        public static func error(format: StaticString) {
            let error = unsafeBitCast(
                system.error,
                to: (@convention(c) (UnsafePointer<CChar>?) -> Void).self
            )
            format.utf8Start.withMemoryRebound(
                to: CChar.self,
                capacity: format.utf8CodeUnitCount
            ) { pointer in
                error(pointer)
            }
        }

        /// Calls the log function, outputting an error in red to the console, then pauses execution.
        public static func error(format: UnsafePointer<CChar>) {
            let error = unsafeBitCast(
                system.error,
                to: (@convention(c) (UnsafePointer<CChar>?) -> Void).self
            )
            error(format)
        }

        /// Calls the log function.
        public static func logToConsole(format: StaticString) {
            let logToConsole = unsafeBitCast(
                system.logToConsole,
                to: (@convention(c) (UnsafePointer<CChar>?) -> Void).self
            )
            format.utf8Start.withMemoryRebound(
                to: CChar.self,
                capacity: format.utf8CodeUnitCount
            ) { pointer in
                logToConsole(pointer)
            }
        }

        /// Calls the log function.
        public static func logToConsole(format: UnsafePointer<CChar>) {
            let logToConsole = unsafeBitCast(
                system.logToConsole,
                to: (@convention(c) (UnsafePointer<CChar>?) -> Void).self
            )
            logToConsole(format)
        }

        // MARK: - Interacting with the System Menu

        /// Adds a new menu item to the System Menu.
        /// - Parameters:
        ///   - title: The title displayed by the menu item.
        ///   - callback: The callback invoked when the menu item is selected by the user.
        ///   - userdata: The userdata to associate with the menu item.
        /// - Returns: The menu item
        public static func addMenuItem(
            title: StaticString,
            callback: (@convention(c) (UnsafeMutableRawPointer?) -> Void)?,
            userdata: UnsafeMutableRawPointer? = nil
        ) -> OpaquePointer {
            system.addMenuItem(title.utf8Start, callback, userdata).unsafelyUnwrapped
        }

        /// Adds a new menu item to the System Menu.
        /// - Parameters:
        ///   - title: The title displayed by the menu item.
        ///   - callback: The callback invoked when the menu item is selected by the user.
        ///   - userdata: The userdata to associate with the menu item.
        /// - Returns: The menu item
        public static func addMenuItem(
            title: UnsafePointer<CChar>,
            callback: (@convention(c) (UnsafeMutableRawPointer?) -> Void)?,
            userdata: UnsafeMutableRawPointer? = nil
        ) -> OpaquePointer {
            system.addMenuItem(title, callback, userdata).unsafelyUnwrapped
        }

        /// Adds a new menu item that can be checked or unchecked by the player.
        /// - Parameters:
        ///   - title: The title displayed by the menu item.
        ///   - checked: Wether or not the menu item is checked.
        ///   - callback: The callback invoked when the menu item is selected by the user.
        ///   - userdata: The userdata to associate with the menu item.
        /// - Returns: The menu item
        public static func addCheckmarkMenuItem(
            title: StaticString,
            checked: Bool,
            callback: (@convention(c) (UnsafeMutableRawPointer?) -> Void)?,
            userdata: UnsafeMutableRawPointer? = nil
        ) -> OpaquePointer {
            system.addCheckmarkMenuItem(title.utf8Start, checked ? 1 : 0, callback, userdata).unsafelyUnwrapped
        }

        /// Adds a new menu item that can be checked or unchecked by the player.
        /// - Parameters:
        ///   - title: The title displayed by the menu item.
        ///   - checked: Wether or not the menu item is checked.
        ///   - callback: The callback invoked when the menu item is selected by the user.
        ///   - userdata: The userdata to associate with the menu item.
        /// - Returns: The menu item
        public static func addCheckmarkMenuItem(
            title: UnsafePointer<CChar>,
            checked: Bool,
            callback: (@convention(c) (UnsafeMutableRawPointer?) -> Void)?,
            userdata: UnsafeMutableRawPointer? = nil
        ) -> OpaquePointer {
            system.addCheckmarkMenuItem(title, checked ? 1 : 0, callback, userdata).unsafelyUnwrapped
        }

        /// Adds a new menu item that allows the player to cycle through a set of options.
        /// - Parameters:
        ///   - title: The title displayed by the menu item.
        ///   - options: An array of strings representing the states this menu item can cycle through. Due to limited horizontal space,
        ///              the option strings and title should be kept short for this type of menu item.
        ///   - optionsCount: The number of items contained in options.
        ///   - callback: The callback invoked when the menu item is selected by the user.
        ///   - userdata: The userdata to associate with the menu item.
        /// - Returns: The menu item
        public static func addOptionsMenuItem(
            title: StaticString,
            options: UnsafeMutablePointer<UnsafePointer<CChar>?>?,
            optionsCount: Int32,
            callback: (@convention(c) (UnsafeMutableRawPointer?) -> Void)?,
            userData: UnsafeMutableRawPointer?
        ) -> OpaquePointer {
            system.addOptionsMenuItem(
                title.utf8Start,
                options,
                optionsCount,
                callback,
                userData
            ).unsafelyUnwrapped
        }

        /// Adds a new menu item that allows the player to cycle through a set of options.
        /// - Parameters:
        ///   - title: The title displayed by the menu item.
        ///   - options: An array of strings representing the states this menu item can cycle through. Due to limited horizontal space,
        ///              the option strings and title should be kept short for this type of menu item.
        ///   - optionsCount: The number of items contained in options.
        ///   - callback: The callback invoked when the menu item is selected by the user.
        ///   - userdata: The userdata to associate with the menu item.
        /// - Returns: The menu item
        public static func addOptionsMenuItem(
            title: UnsafePointer<CChar>,
            options: UnsafeMutablePointer<UnsafePointer<CChar>?>?,
            optionsCount: Int32,
            callback: (@convention(c) (UnsafeMutableRawPointer?) -> Void)?,
            userData: UnsafeMutableRawPointer?
        ) -> OpaquePointer {
            system.addOptionsMenuItem(
                title,
                options,
                optionsCount,
                callback,
                userData
            ).unsafelyUnwrapped
        }

        /// Removes the menu item from the system menu.
        public static func removeMenuItem(_ menuItem: OpaquePointer) {
            system.removeMenuItem(menuItem)
        }

        /// Removes all custom menu items from the system menu.
        public static func removeAllMenuItems() {
            system.removeAllMenuItems()
        }

        /// Gets the title of the menu item.
        public static func getMenuItemTitle(_ menuItem: OpaquePointer) -> UnsafePointer<CChar> {
            system.getMenuItemTitle(menuItem).unsafelyUnwrapped
        }

        /// Sets the display title of the menu item.
        public static func setMenuItemTitle(_ menuItem: OpaquePointer, title: StaticString) {
            system.setMenuItemTitle(menuItem, title.utf8Start)
        }

        /// Sets the display title of the menu item.
        public static func setMenuItemTitle(_ menuItem: OpaquePointer, title: UnsafePointer<CChar>) {
            system.setMenuItemTitle(menuItem, title)
        }

        /// Gets the value of the menu item.
        ///
        /// For checkmark menu items, 1 means checked, 0 unchecked.
        /// For option menu items, the value indicates the array index of the currently selected option.
        public static func getMenuItemValue(_ menuItem: OpaquePointer) -> Int32 {
            system.getMenuItemValue(menuItem)
        }

        /// Sets the value of the menu item.
        ///
        /// For checkmark menu items, 1 means checked, 0 unchecked.
        /// For option menu items, the value indicates the array index of the currently selected option.
        public static func setMenuItemValue(_ menuItem: OpaquePointer, value: Int32) {
            system.setMenuItemValue(menuItem, value)
        }

        /// Gets the userdata value associated with this menu item.
        public static func getMenuItemUserdata(_ menuItem: OpaquePointer) -> UnsafeMutableRawPointer {
            system.getMenuItemUserdata(menuItem).unsafelyUnwrapped
        }

        /// Sets the userdata value associated with this menu item.
        public static func setMenuItemUserdata(_ menuItem: OpaquePointer, userdata: UnsafeMutableRawPointer) {
            system.setMenuItemUserdata(menuItem, userdata)
        }

        /// Returns the number of seconds (and sets milliseconds if not NULL) elapsed since midnight (hour 0), January 1, 2000.
        public static func getSecondsSinceEpoch(_ epoch: UInt32) -> UInt32 {
            var epoch = epoch
            return system.getSecondsSinceEpoch(&epoch)
        }

        /// Resets the high-resolution timer.
        public static func resetElapsedTime() {
            system.resetElapsedTime()
        }

        /// Converts the given epoch time to a PDDateTime.
        public static func convertEpochToDateTime(_ epoch: UInt32, dateTime: inout PDDateTime) {
            system.convertEpochToDateTime(epoch, &dateTime)
        }

        /// Converts the given PDDateTime to an epoch time.
        public static func convertDateTimeToEpoch(_ dateTime: PDDateTime) -> UInt32 {
            var dateTime = dateTime
            return system.convertDateTimeToEpoch(&dateTime)
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
        public static func setMenuImage(_ bitmap: OpaquePointer, xOffset: Int32) {
            system.setMenuImage(bitmap, xOffset)
        }

        /// Replaces the default Lua run loop function with a custom update function.
        ///
        /// The update function should return a non-zero number to tell the system to update the display, or zero if update isn’t needed.
        public static func setUpdateCallback(
            update: @convention(c) (UnsafeMutableRawPointer?) -> Int32,
            userdata: UnsafeMutableRawPointer?
        ) {
            system.setUpdateCallback(update, userdata)
        }

        /// Provides a callback to receive messages sent to the device over the serial port using the msg command.
        ///
        /// If no device is connected, you can send these messages to a game in the simulator by entering `!msg <message>` in the Lua console.
        public static func setSerialMessageCallback(
            callback: @convention(c) (UnsafePointer<CChar>?) -> Void
        ) {
            system.setSerialMessageCallback(callback)
        }

        /// Calculates the current frames per second and draws that value at `x`, `y`.
        public static func drawFPS(x: Int32, y: Int32) {
            system.drawFPS(x, y)
        }

        /// Flush the CPU instruction cache, on the very unlikely chance you’re modifying instruction code on the fly.
        /// (If you don’t know what I’m talking about, you don’t need this. :smile:)
        public static func clearICache() {
            system.clearICache()
        }

        /// By default, the accelerometer is disabled to save (a small amount of) power.
        /// To use a peripheral, it must first be enabled via this function. Accelerometer data is not available
        /// until the next update cycle after it’s enabled.
        public static func setPeripheralsEnabled(_ peripherals: PDPeripherals) {
            system.setPeripheralsEnabled(peripherals)
        }

        /// Disables or enables the 3 minute auto lock feature. When called, the timer is reset to 3 minutes.
        public static func setAutoLockDisabled(_ disabled: Bool) {
            system.setAutoLockDisabled(disabled ? 1 : 0)
        }

        /// The function returns the previous value for this setting.
        public static func setCrankSoundsDisabled(_ disabled: Bool) -> Bool {
            system.setCrankSoundsDisabled(disabled ? 1 : 0) != 0
        }

        /// As an alternative to polling for button presses using getButtonState(), this function allows a callback function to be set.
        /// The function is called for each button up/down event (possibly multiple events on the same button) that occurred during
        /// the previous update cycle. At the default 30 FPS, a queue size of 5 should be adequate. At lower frame rates/longer frame times,
        /// the queue size should be extended until all button presses are caught. The function should return 0 on success or a non-zero
        /// value to signal an error.
        public static func setButtonCallback(
            callback: (@convention(c) (PDButtons, Int32, UInt32, UnsafeMutableRawPointer?) -> Int32)?,
            buttonud: UnsafeMutableRawPointer?, // ???
            queueSize: Int32
        ) {
            system.setButtonCallback(callback, buttonud, queueSize)
        }

        // MARK: Private

        private static var system: playdate_sys { playdateAPI.system.pointee }
    }
}
