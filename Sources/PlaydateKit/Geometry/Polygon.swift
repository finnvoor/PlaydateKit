/// A structure that contains a two-dimensional open or closed polygon.
public struct Polygon<T: Numeric>: Equatable {
    // MARK: Lifecycle

    /// Creates a polygon with the specified vertices.
    public init(vertices: [Point<T>]) {
        self.vertices = vertices
    }

    // MARK: Public

    /// The polygon's vertices.
    public var vertices: [Point<T>]

    /// Returns true if the polygon is closed, false if not.
    public var isClosed: Bool { (vertices.first == vertices.last) && vertices.first != nil }

    /// Closes the polygon. If the polygon’s first and last point aren’t coincident, a point equal to the first point will be added.
    public mutating func close() {
        guard !isClosed, let first = vertices.first else { return }
        vertices.append(first)
    }
}
