// MARK: - Point

/// A structure that contains a point in a two-dimensional coordinate system.
public struct Point<T: Numeric>: Equatable {
    // MARK: Lifecycle

    public init(x: T, y: T) {
        self.x = x
        self.y = y
    }

    // MARK: Public

    public var x, y: T
}

// MARK: AffineTransformable

extension Point: AffineTransformable where T == Float {
    public mutating func transform(by transform: AffineTransform) {
        let newX = transform.m11 * x + transform.m12 * y + transform.tx
        let newY = transform.m21 * x + transform.m22 * y + transform.ty
        self = Point(x: newX, y: newY)
    }
}

public extension Point {
    /// The point with location (0,0).
    static var zero: Point<T> { Point(x: 0, y: 0) }
}
