// MARK: - Rect

/// A structure that contains the location and dimensions of a rectangle.
public struct Rect<T: Numeric>: Equatable {
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

// MARK: AffineTransformable

extension Rect: AffineTransformable where T == Float {
    public mutating func transform(by transform: AffineTransform) {
        let transformedOrigin = Point(x: x, y: y).transformed(by: transform)
        let transformedTopRight = Point(x: x + width, y: y + height).transformed(by: transform)
        x = transformedOrigin.x
        y = transformedOrigin.y
        width = transformedTopRight.x - transformedOrigin.x
        height = transformedTopRight.y - transformedOrigin.y
    }
}

public extension Rect {
    /// The point with location (0,0).
    static var zero: Rect<T> { Rect(x: 0, y: 0, width: 0, height: 0) }
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
