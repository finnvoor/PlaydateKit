public import CPlaydate

// MARK: - Rect

/// A structure that contains the location and dimensions of a rectangle.
public struct Rect<T: Numeric> {
    // MARK: Lifecycle

    public init(x: T, y: T, width: T, height: T) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public init(origin: Point<T>, width: T, height: T) {
        x = origin.x
        y = origin.y
        self.width = width
        self.height = height
    }

    // MARK: Public

    public var x, y, width, height: T
}

public extension Rect {
    /// The point with location (0,0).
    static var zero: Rect<T> { Rect(x: 0, y: 0, width: 0, height: 0) }
}

public extension Rect {
    /// Returns a rectangle with an origin that is offset from that of the source rectangle.
    func offsetBy(dx: T, dy: T) -> Rect {
        Rect(x: x + dx, y: y + dy, width: width, height: height)
    }
}

extension Rect where T == CInt {
    var lcdRect: LCDRect {
        LCDMakeRect(x, y, width, height)
    }

    init(_ lcdRect: LCDRect) {
        x = lcdRect.left
        y = lcdRect.top
        width = lcdRect.right - lcdRect.left
        height = lcdRect.bottom - lcdRect.top
    }
}

extension Rect where T == Float {
    var pdRect: PDRect {
        PDRect(x: x, y: y, width: width, height: height)
    }

    init(_ pdRect: PDRect) {
        x = pdRect.x
        y = pdRect.y
        width = pdRect.width
        height = pdRect.height
    }
}
