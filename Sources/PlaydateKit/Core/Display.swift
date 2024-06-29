public import CPlaydate

/// Functions pertaining to Playdate’s screen.
public enum Display {
    // MARK: Public

    /// Returns the height of the display, taking the current scale into account;
    /// e.g., if the scale is 2, this function returns 120 instead of 240.
    public static var height: CInt {
        display.getHeight.unsafelyUnwrapped()
    }

    /// Returns the width of the display, taking the current scale into account;
    /// e.g., if the scale is 2, this function returns 200 instead of 400.
    public static var width: CInt {
        display.getWidth.unsafelyUnwrapped()
    }

    /// The nominal refresh rate in frames per second. The default is 30 fps, which is a recommended
    /// figure that balances animation smoothness with performance and power considerations. Maximum is 50 fps.
    ///
    /// If rate is 0, the game’s update callback (the function specified by `Playdate.updateCallback`) is called as soon as possible.
    /// Since the display refreshes line-by-line, and unchanged lines aren’t sent to the display,
    /// the update cycle will be faster than 30 times a second but at an indeterminate rate.
    public static var refreshRate: Float {
        get { _refreshRate }
        set {
            var refreshRate = newValue
            if !((0...50) ~= refreshRate) {
                System.error("refreshRate must be between 0...50")
                refreshRate = min(max(refreshRate, 0), 50)
            }
            _refreshRate = refreshRate
            display.setRefreshRate.unsafelyUnwrapped(refreshRate)
        }
    }

    /// If inverted is true, the frame buffer is drawn inverted—black instead of white, and vice versa.
    public static var inverted: Bool {
        get { _inverted }
        set {
            _inverted = newValue
            display.setInverted.unsafelyUnwrapped(newValue ? 1 : 0)
        }
    }

    /// Sets the display scale factor. Valid values for scale are 1, 2, 4, and 8.
    ///
    /// The top-left corner of the frame buffer is scaled up to fill the display; e.g., if the scale is set to 4,
    /// the pixels in rectangle [0,100] x [0,60] are drawn on the screen as 4 x 4 squares.
    public static var scale: CUnsignedInt {
        get { _scale }
        set {
            var scale = newValue
            if !([1, 2, 4, 8].contains(scale)) {
                System.error("scale must be 1, 2, 4, or 8")
                scale = 1
            }
            _scale = scale
            display.setScale.unsafelyUnwrapped(scale)
        }
    }

    /// Flips the display on the x or y axis, or both.
    public static var flipped: (x: Bool, y: Bool) {
        get { _flipped }
        set {
            _flipped = newValue
            display.setFlipped.unsafelyUnwrapped(newValue.x ? 1 : 0, newValue.y ? 1 : 0)
        }
    }

    /// Adds a mosaic effect to the display. Valid x and y values are between 0 and 3, inclusive.
    public static func setMosaic(x: CUnsignedInt, y: CUnsignedInt) {
        display.setMosaic.unsafelyUnwrapped(x, y)
    }

    /// Offsets the display by the given amount.
    /// Areas outside of the displayed area are filled with the current background color.
    public static func setOffset(dx: CInt, dy: CInt) {
        display.setOffset.unsafelyUnwrapped(dx, dy)
    }

    // MARK: Private

    private nonisolated(unsafe) static var _flipped: (x: Bool, y: Bool) = (false, false)

    private nonisolated(unsafe) static var _scale: CUnsignedInt = 1

    private nonisolated(unsafe) static var _inverted = false

    private nonisolated(unsafe) static var _refreshRate: Float = 30

    private static var display: playdate_display { Playdate.playdateAPI.display.pointee }
}
