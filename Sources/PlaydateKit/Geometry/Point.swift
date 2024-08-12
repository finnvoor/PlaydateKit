// MARK: - Point

/// A structure that contains a point in a two-dimensional coordinate system.
public struct Point: Equatable {
    // MARK: Lifecycle

    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }

    @_disfavoredOverload public init(x: Int, y: Int) {
        self.x = Float(x)
        self.y = Float(y)
    }

    // MARK: Public

    /// The point with location (0,0).
    public static var zero: Point { Point(x: 0, y: 0) }

    public var x, y: Float
}

public extension Point {
    static func + (lhs: Point, rhs: Point) -> Point {
        Point(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func += (lhs: inout Point, rhs: Point) {
        lhs = lhs + rhs
    }

    static func - (lhs: Point, rhs: Point) -> Point {
        Point(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func -= (lhs: inout Point, rhs: Point) {
        lhs = lhs - rhs
    }

    static func * (lhs: Point, rhs: Point) -> Point {
        Point(x: lhs.x * rhs.x, y: lhs.y * rhs.y)
    }

    static func *= (lhs: inout Point, rhs: Point) {
        lhs = lhs * rhs
    }

    static func * (lhs: Point, rhs: Float) -> Point {
        Point(x: lhs.x * rhs, y: lhs.y * rhs)
    }

    static func *= (lhs: inout Point, rhs: Float) {
        lhs = lhs * rhs
    }

    static func / (lhs: Point, rhs: Point) -> Point {
        Point(x: lhs.x / rhs.x, y: lhs.y / rhs.y)
    }

    static func /= (lhs: inout Point, rhs: Point) {
        lhs = lhs / rhs
    }

    static func / (lhs: Point, rhs: Float) -> Point {
        Point(x: lhs.x / rhs, y: lhs.y / rhs)
    }

    static func /= (lhs: inout Point, rhs: Float) {
        lhs = lhs / rhs
    }

    static prefix func - (point: Point) -> Point {
        Point(x: -point.x, y: -point.y)
    }
}

// MARK: AffineTransformable

extension Point: AffineTransformable {
    public mutating func transform(by transform: AffineTransform) {
        let newX = transform.m11 * x + transform.m12 * y + transform.tx
        let newY = transform.m21 * x + transform.m22 * y + transform.ty
        self = Point(x: newX, y: newY)
    }
}
