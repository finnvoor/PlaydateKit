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

    @_disfavoredOverload public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = Float(x)
        self.y = Float(y)
        self.width = Float(width)
        self.height = Float(height)
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

    public var origin: Point {
        get {
            Point(x: x, y: y)
        } set {
            x = newValue.x
            y = newValue.y
        }
    }

    public var center: Point {
        get {
            Point(x: x + width / 2, y: y + height / 2)
        } set {
            x = newValue.x - width / 2
            y = newValue.y - height / 2
        }
    }

    public var minX: Float {
        min(x, x + width)
    }

    public var minY: Float {
        min(y, y + height)
    }

    public var maxX: Float {
        max(x, x + width)
    }

    public var maxY: Float {
        max(y, y + height)
    }
}

public extension Rect {
    /// Returns a rectangle that is smaller or larger than the source rectangle, with the same center point.
    /// - Parameters:
    ///   - dx: The x-coordinate value to use for adjusting the source rectangle. To create an inset rectangle, specify a positive value.
    ///   To create a larger, encompassing rectangle, specify a negative value.
    ///   - dy: The y-coordinate value to use for adjusting the source rectangle. To create an inset rectangle, specify a positive value.
    ///   To create a larger, encompassing rectangle, specify a negative value.
    /// - Returns: A rectangle. The origin value is offset in the x-axis by the distance specified by the dx parameter and in the y-axis
    /// by the distance specified by the dy parameter, and its size adjusted by (2*dx,2*dy), relative to the source rectangle. If dx and dy
    /// are positive values, then the rectangle’s size is decreased. If dx and dy are negative values, the rectangle’s size is increased.
    func insetBy(dx: Float, dy: Float) -> Rect {
        Rect(
            x: x + dx,
            y: y + dy,
            width: width - (dx * 2),
            height: height - (dy * 2)
        )
    }
}

public extension Rect {
    static func + (lhs: Rect, rhs: Rect) -> Rect {
        Rect(
            x: lhs.x + rhs.x,
            y: lhs.y + rhs.y,
            width: lhs.width + rhs.width,
            height: lhs.height + rhs.height
        )
    }

    static func += (lhs: inout Rect, rhs: Rect) {
        lhs = lhs + rhs
    }

    static func - (lhs: Rect, rhs: Rect) -> Rect {
        Rect(
            x: lhs.x - rhs.x,
            y: lhs.y - rhs.y,
            width: lhs.width - rhs.width,
            height: lhs.height - rhs.height
        )
    }

    static func -= (lhs: inout Rect, rhs: Rect) {
        lhs = lhs - rhs
    }

    static func * (lhs: Rect, rhs: Rect) -> Rect {
        Rect(
            x: lhs.x * rhs.x,
            y: lhs.y * rhs.y,
            width: lhs.width * rhs.width,
            height: lhs.height * rhs.height
        )
    }

    static func *= (lhs: inout Rect, rhs: Rect) {
        lhs = lhs * rhs
    }

    static func * (lhs: Rect, rhs: Float) -> Rect {
        Rect(
            x: lhs.x * rhs,
            y: lhs.y * rhs,
            width: lhs.width * rhs,
            height: lhs.height * rhs
        )
    }

    static func *= (lhs: inout Rect, rhs: Float) {
        lhs = lhs * rhs
    }

    static func / (lhs: Rect, rhs: Rect) -> Rect {
        Rect(
            x: lhs.x / rhs.x,
            y: lhs.y / rhs.y,
            width: lhs.width / rhs.width,
            height: lhs.height / rhs.height
        )
    }

    static func /= (lhs: inout Rect, rhs: Rect) {
        lhs = lhs / rhs
    }

    static func / (lhs: Rect, rhs: Float) -> Rect {
        Rect(
            x: lhs.x / rhs,
            y: lhs.y / rhs,
            width: lhs.width / rhs,
            height: lhs.height / rhs
        )
    }

    static func /= (lhs: inout Rect, rhs: Float) {
        lhs = lhs / rhs
    }
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
