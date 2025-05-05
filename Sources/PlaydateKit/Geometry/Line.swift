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

public extension Line {
    static func + (lhs: Line, rhs: Line) -> Line {
        Line(start: lhs.start + rhs.start, end: lhs.end + rhs.end)
    }

    static func += (lhs: inout Line, rhs: Line) {
        lhs = lhs + rhs
    }

    static func - (lhs: Line, rhs: Line) -> Line {
        Line(start: lhs.start - rhs.start, end: lhs.end - rhs.end)
    }

    static func -= (lhs: inout Line, rhs: Line) {
        lhs = lhs - rhs
    }

    static func * (lhs: Line, rhs: Line) -> Line {
        Line(start: lhs.start * rhs.start, end: lhs.end * rhs.end)
    }

    static func *= (lhs: inout Line, rhs: Line) {
        lhs = lhs * rhs
    }

    static func * (lhs: Line, rhs: Float) -> Line {
        Line(start: lhs.start * rhs, end: lhs.end * rhs)
    }

    static func *= (lhs: inout Line, rhs: Float) {
        lhs = lhs * rhs
    }

    static func / (lhs: Line, rhs: Line) -> Line {
        Line(start: lhs.start / rhs.start, end: lhs.end / rhs.end)
    }

    static func /= (lhs: inout Line, rhs: Line) {
        lhs = lhs / rhs
    }

    static func / (lhs: Line, rhs: Float) -> Line {
        Line(start: lhs.start / rhs, end: lhs.end / rhs)
    }

    static func /= (lhs: inout Line, rhs: Float) {
        lhs = lhs / rhs
    }

    static prefix func - (point: Line) -> Line {
        Line(start: -point.start, end: -point.end)
    }
}

// MARK: AffineTransformable

extension Line: AffineTransformable {
    public mutating func transform(by transform: AffineTransform) {
        start.transform(by: transform)
        end.transform(by: transform)
    }
}
