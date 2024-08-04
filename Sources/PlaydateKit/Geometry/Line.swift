// MARK: - Line

/// A structure representing a line with a start and end point in a two-dimensional coordinate system.
public struct Line<T: Numeric>: Equatable {
    // MARK: Lifecycle

    public init(start: Point<T>, end: Point<T>) {
        self.start = start
        self.end = end
    }

    // MARK: Public

    public var start, end: Point<T>
}

// MARK: AffineTransformable

extension Line: AffineTransformable where T == Float {
    public mutating func transform(by transform: AffineTransform) {
        start.transform(by: transform)
        end.transform(by: transform)
    }
}

public extension Line {
    /// The line whose start and end are both located at (0, 0).
    static var zero: Line<T> { Line(start: .zero, end: .zero) }
}
