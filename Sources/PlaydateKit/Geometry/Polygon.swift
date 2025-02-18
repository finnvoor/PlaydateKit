// MARK: - Polygon

/// A structure that contains a two-dimensional open or closed polygon.
public struct Polygon: Equatable {
    // MARK: Lifecycle

    /// Creates a polygon with the specified vertices.
    public init(vertices: [Point]) {
        self.vertices = vertices
    }

    // MARK: Public

    /// The polygon's vertices.
    public var vertices: [Point]

    /// Returns true if the polygon is closed, false if not.
    public var isClosed: Bool { (vertices.first == vertices.last) && vertices.first != nil }

    /// Closes the polygon. If the polygon’s first and last point aren’t coincident, a point equal to the first point will be added.
    public mutating func close() {
        guard !isClosed, let first = vertices.first else { return }
        vertices.append(first)
    }
}

// MARK: - [Point] + AffineTransformable

extension [Point]: AffineTransformable {
    public mutating func transform(by transform: AffineTransform) {
        for i in indices {
            self[i].transform(by: transform)
        }
    }
}

// MARK: - Polygon + AffineTransformable

extension Polygon: AffineTransformable {
    public mutating func transform(by transform: AffineTransform) {
        vertices.transform(by: transform)
    }
}
