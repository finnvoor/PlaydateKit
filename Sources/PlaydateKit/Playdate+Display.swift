@preconcurrency public import CPlaydate

public extension Playdate {
    enum Display {
        // MARK: Public

        /// Returns the height of the display, taking the current scale into account;
        /// e.g., if the scale is 2, this function returns 120 instead of 240.
        public static var height: Int32 {
            display.getHeight()
        }

        /// Returns the width of the display, taking the current scale into account;
        /// e.g., if the scale is 2, this function returns 200 instead of 400.
        public static var width: Int32 {
            display.getWidth()
        }

        /// If inverted is true, the frame buffer is drawn inverted—black instead of white, and vice versa.
        public static func setInverted(_ inverted: Bool) {
            display.setInverted(inverted ? 1 : 0)
        }

        /// Adds a mosaic effect to the display. Valid x and y values are between 0 and 3, inclusive.
        public static func setMosaic(x: UInt32, y: UInt32) {
            display.setMosaic(x, y)
        }

        /// Flips the display on the x or y axis, or both.
        public static func setFlipped(x: Bool, y: Bool) {
            display.setFlipped(x ? 1 : 0, y ? 1 : 0)
        }

        /// Sets the nominal refresh rate in frames per second. The default is 30 fps, which is a recommended
        /// figure that balances animation smoothness with performance and power considerations. Maximum is 50 fps.
        ///
        /// If rate is 0, the game’s update callback (either Lua’s playdate.update() or the function specified by playdate→system→setUpdateCallback()) is called as soon as possible.
        /// Since the display refreshes line-by-line, and unchanged lines aren’t sent to the display,
        /// the update cycle will be faster than 30 times a second but at an indeterminate rate.
        public static func setRefreshRate(_ rate: Float) {
            display.setRefreshRate(rate)
        }

        /// Sets the display scale factor. Valid values for scale are 1, 2, 4, and 8.
        ///
        /// The top-left corner of the frame buffer is scaled up to fill the display; e.g., if the scale is set to 4,
        /// the pixels in rectangle [0,100] x [0,60] are drawn on the screen as 4 x 4 squares.
        public static func setScale(_ scale: UInt32) {
            display.setScale(scale)
        }

        /// Offsets the display by the given amount.
        /// Areas outside of the displayed area are filled with the current background color.
        public static func setOffset(dx: Int32, dy: Int32) {
            display.setOffset(dx, dy)
        }

        // MARK: Private

        private static var display: playdate_display { playdateAPI.display.pointee }
    }
}