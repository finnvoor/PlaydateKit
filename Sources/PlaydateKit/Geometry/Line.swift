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

public extension Line {
    /// The line whose start and end are both located at (0, 0).
    static var zero: Line<T> { Line(start: .zero, end: .zero) }
}

public extension Line {
    /// Returns a line with a start and end that is offset from that of the source line.
    func offsetBy(dx: T, dy: T) -> Line {
        Line(
            start: start.offsetBy(dx: dx, dy: dy),
            end: end.offsetBy(dx: dx, dy: dy)
        )
    }
}
