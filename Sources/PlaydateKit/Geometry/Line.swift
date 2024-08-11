// MARK: - Line

/// A structure representing a line with a start and end point in a two-dimensional coordinate system.
public struct Line: Equatable {
    // MARK: Lifecycle

    public init(start: Point, end: Point) {
        self.start = start
        self.end = end
    }

    // MARK: Public

    /// The line whose start and end are both located at (0, 0).
    public static var zero: Line { Line(start: .zero, end: .zero) }

    public var start, end: Point
}

// MARK: AffineTransformable

extension Line: AffineTransformable {
    public mutating func transform(by transform: AffineTransform) {
        start.transform(by: transform)
        end.transform(by: transform)
    }
}
