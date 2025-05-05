public import CPlaydate

/// Functions pertaining to Playdate’s screen.
public enum Display {
    // MARK: Public

    public enum Scale: CUnsignedInt {
        case oneTimes = 1
        case twoTimes = 2
        case fourTimes = 4
        case eightTimes = 8

        // MARK: Public

        public var next: Scale {
            switch self {
            case .oneTimes: .twoTimes
            case .twoTimes: .fourTimes
            case .fourTimes: .eightTimes
            case .eightTimes: .eightTimes
            }
        }

        public var previous: Scale {
            switch self {
            case .oneTimes: .oneTimes
            case .twoTimes: .oneTimes
            case .fourTimes: .twoTimes
            case .eightTimes: .fourTimes
            }
        }
    }

    /// Returns the height of the display, taking the current scale into account;
    /// e.g., if the scale is 2, this function returns 120 instead of 240.
    public static var height: Int {
        Int(display.getHeight.unsafelyUnwrapped())
    }

    /// Returns the width of the display, taking the current scale into account;
    /// e.g., if the scale is 2, this function returns 200 instead of 400.
    public static var width: Int {
        Int(display.getWidth.unsafelyUnwrapped())
    }

    /// Returns the center of the display, taking the current scale into account;
    /// e.g., if the scale is 2, this function returns (60,100) instead of (120,200).
    public static var center: Point {
        Point(x: Float(width) / 2, y: Float(height) / 2)
    }

    /// The nominal refresh rate in frames per second. The default is 30 fps, which is a recommended
    /// figure that balances animation smoothness with performance and power considerations. Maximum is 50 fps.
    ///
    /// If rate is 0, the game’s update callback (the function specified by ``PlaydateGame/update()``) is called as soon as possible.
    /// Since the display refreshes line-by-line, and unchanged lines aren’t sent to the display,
    /// the update cycle will be faster than 30 times a second but at an indeterminate rate.
    public static var refreshRate: Float {
        get { display.getRefreshRate() }
        set { display.setRefreshRate.unsafelyUnwrapped(refreshRate) }
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
    public static var scale: Scale {
        get { _scale }
        set {
            _scale = newValue
            display.setScale.unsafelyUnwrapped(newValue.rawValue)
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
    public static func setOffset(dx: Int, dy: Int) {
        display.setOffset.unsafelyUnwrapped(CInt(dx), CInt(dy))
    }

    // MARK: Private

    private nonisolated(unsafe) static var _flipped: (x: Bool, y: Bool) = (false, false)

    private nonisolated(unsafe) static var _scale = Scale.oneTimes

    private nonisolated(unsafe) static var _inverted = false

    private static var display: playdate_display { Playdate.playdateAPI.display.pointee }
}
