// MARK: - Point

/// A structure that contains a point in a two-dimensional coordinate system.
public struct Point: Equatable {
    // MARK: Lifecycle

    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }

    // MARK: Public

    /// The point with location (0,0).
    public static var zero: Point { Point(x: 0, y: 0) }

    public var x, y: Float
}

// MARK: AffineTransformable

extension Point: AffineTransformable {
    public mutating func transform(by transform: AffineTransform) {
        let newX = transform.m11 * x + transform.m12 * y + transform.tx
        let newY = transform.m21 * x + transform.m22 * y + transform.ty
        self = Point(x: newX, y: newY)
    }
}
