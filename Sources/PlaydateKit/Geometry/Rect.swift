// MARK: - Rect

/// A structure that contains the location and dimensions of a rectangle.
public struct Rect: Equatable {
    // MARK: Lifecycle

    public init(x: Float, y: Float, width: Float, height: Float) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public init(origin: Point, width: Float, height: Float) {
        x = origin.x
        y = origin.y
        self.width = width
        self.height = height
    }

    // MARK: Public

    /// The point with location (0,0).
    public static var zero: Rect { Rect(x: 0, y: 0, width: 0, height: 0) }

    public var x, y, width, height: Float
}

// MARK: AffineTransformable

extension Rect: AffineTransformable {
    public mutating func transform(by transform: AffineTransform) {
        let transformedOrigin = Point(x: x, y: y).transformed(by: transform)
        let transformedTopRight = Point(x: x + width, y: y + height).transformed(by: transform)
        x = transformedOrigin.x
        y = transformedOrigin.y
        width = transformedTopRight.x - transformedOrigin.x
        height = transformedTopRight.y - transformedOrigin.y
    }
}

// MARK: - Rect + LCDRect

public extension Rect {
    var lcdRect: LCDRect {
        LCDMakeRect(CInt(x), CInt(y), CInt(width), CInt(height))
    }

    init(_ lcdRect: LCDRect) {
        x = Float(lcdRect.left)
        y = Float(lcdRect.top)
        width = Float(lcdRect.right) - Float(lcdRect.left)
        height = Float(lcdRect.bottom) - Float(lcdRect.top)
    }
}

// MARK: - Rect + PDRect

public extension Rect {
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
