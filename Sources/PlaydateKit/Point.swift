// MARK: - Point

/// A structure that contains a point in a two-dimensional coordinate system.
public struct Point<T: Numeric> {
    // MARK: Lifecycle

    public init(x: T, y: T) {
        self.x = x
        self.y = y
    }

    // MARK: Public

    public var x, y: T
}

public extension Point {
    /// The point with location (0,0).
    static var zero: Point<T> { Point(x: 0, y: 0) }
}

public extension Point {
    /// Returns a point that is offset from that of the source point.
    func offsetBy(dx: T, dy: T) -> Point {
        Point(x: x + dx, y: y + dy)
    }
}
