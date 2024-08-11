// MARK: - AffineTransformable

public protocol AffineTransformable {
    mutating func transform(by transform: AffineTransform)
}

public extension AffineTransformable {
    func transformed(by transform: AffineTransform) -> Self {
        var result = self
        result.transform(by: transform)
        return result
    }

    mutating func translateBy(dx: Float, dy: Float) {
        transform(by: .init(translationX: dx, y: dy))
    }

    func translatedBy(dx: Float, dy: Float) -> Self {
        transformed(by: .init(translationX: dx, y: dy))
    }

    /// - Parameter angle: The rotation angle in degrees.
    mutating func rotateBy(angle: Float) {
        transform(by: .init(rotationAngle: angle))
    }

    /// - Parameter angle: The rotation angle in degrees.
    func rotatedBy(angle: Float) -> Self {
        transformed(by: .init(rotationAngle: angle))
    }

    mutating func scaleBy(x: Float, y: Float) {
        transform(by: .init(scaleX: x, y: y))
    }

    func scaledBy(x: Float, y: Float) -> Self {
        transformed(by: .init(scaleX: x, y: y))
    }
}

// MARK: - AffineTransform

public struct AffineTransform: Equatable {
    // MARK: Lifecycle

    /// Returns an affine transformation matrix constructed from translation values you provide.
    public init(translationX x: Float, y: Float) {
        m11 = 1
        m12 = 0
        m21 = 0
        m22 = 1
        tx = x
        ty = y
    }

    /// Returns an affine transformation matrix constructed from a rotation value you provide.
    /// - Parameter rotationAngle: The rotation angle in degrees.
    public init(rotationAngle: Float) {
        let rotationAngleRadians = rotationAngle * Float.pi / 180
        m11 = cosf(rotationAngleRadians)
        m12 = -sinf(rotationAngleRadians)
        m21 = sinf(rotationAngleRadians)
        m22 = cosf(rotationAngleRadians)
        tx = 0
        ty = 0
    }

    /// Returns an affine transformation matrix constructed from scaling values you provide.
    public init(scaleX x: Float, y: Float) {
        m11 = x
        m12 = 0
        m21 = 0
        m22 = y
        tx = 0
        ty = 0
    }

    public init(m11: Float, m12: Float, m21: Float, m22: Float, tx: Float, ty: Float) {
        self.m11 = m11
        self.m12 = m12
        self.m21 = m21
        self.m22 = m22
        self.tx = tx
        self.ty = ty
    }

    // MARK: Public

    /// The identity transform.
    public nonisolated(unsafe) static let identity = AffineTransform(m11: 1, m12: 0, m21: 0, m22: 1, tx: 0, ty: 0)

    /// The entry at position [1,1] in the matrix.
    public var m11: Float
    /// The entry at position [1,2] in the matrix.
    public var m12: Float
    /// The entry at position [2,1] in the matrix.
    public var m21: Float
    /// The entry at position [2,2] in the matrix.
    public var m22: Float
    /// The entry at position [3,1] in the matrix.
    public var tx: Float
    /// The entry at position [3,2] in the matrix.
    public var ty: Float

    /// Returns an affine transformation matrix constructed by combining two existing affine transforms.
    public func concatenating(_ transform: AffineTransform) -> AffineTransform {
        AffineTransform(
            m11: m11 * transform.m11 + m12 * transform.m21,
            m12: m11 * transform.m12 + m12 * transform.m22,
            m21: m21 * transform.m11 + m22 * transform.m21,
            m22: m21 * transform.m12 + m22 * transform.m22,
            tx: tx + transform.tx,
            ty: ty + transform.ty
        )
    }

    /// Inverts the affine transform.
    ///
    /// If the affine transform cannot be inverted, the affine transform is unchanged.
    public mutating func invert() {
        let determinant = m11 * m22 - m12 * m21
        if determinant != 0 {
            let inverseDet = 1 / determinant
            let tmp11 = m22 * inverseDet
            let tmp12 = -m12 * inverseDet
            let tmp21 = -m21 * inverseDet
            let tmp22 = m11 * inverseDet
            let tmpTx = (m21 * ty - m22 * tx) * inverseDet
            let tmpTy = (m12 * tx - m11 * ty) * inverseDet
            m11 = tmp11
            m12 = tmp12
            m21 = tmp21
            m22 = tmp22
            tx = tmpTx
            ty = tmpTy
        }
    }

    /// Returns an affine transformation matrix constructed by inverting the affine transform.
    ///
    /// If the affine transform cannot be inverted, the affine transform is returned unchanged.
    public func inverted() -> AffineTransform {
        var result = self
        result.invert()
        return result
    }

    /// Translates the affine transform.
    public mutating func translateBy(dx: Float, dy: Float) {
        tx += dx
        ty += dy
    }

    /// Returns an affine transformation matrix constructed by translating the affine transform.
    public func translatedBy(dx: Float, dy: Float) -> AffineTransform {
        var result = self
        result.translateBy(dx: dx, dy: dy)
        return result
    }

    /// Rotates the affine transform.
    /// - Parameter angle: The rotation angle in degrees.
    public mutating func rotateBy(angle: Float) {
        let cosAngle = cosf(angle)
        let sinAngle = sinf(angle)
        let new11 = m11 * cosAngle + m12 * sinAngle
        let new12 = m12 * cosAngle - m11 * sinAngle
        let new21 = m21 * cosAngle + m22 * sinAngle
        let new22 = m22 * cosAngle - m21 * sinAngle
        m11 = new11
        m12 = new12
        m21 = new21
        m22 = new22
    }

    /// Returns an affine transformation matrix constructed by rotating the affine transform.
    /// - Parameter angle: The rotation angle in degrees.
    public func rotatedBy(angle: Float) -> AffineTransform {
        var result = self
        result.rotateBy(angle: angle)
        return result
    }

    /// Scales the affine transform.
    public mutating func scaleBy(x: Float, y: Float) {
        m11 *= x
        m12 *= y
        m21 *= x
        m22 *= y
    }

    /// Returns an affine transformation matrix constructed by scaling the affine transform.
    public func scaledBy(x: Float, y: Float) -> AffineTransform {
        var result = self
        result.scaleBy(x: x, y: y)
        return result
    }
}
