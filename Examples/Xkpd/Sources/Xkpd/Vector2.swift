import PlaydateKit

typealias Vector2 = Point

extension Vector2 {
    var length: Float {
      return sqrtf(x * x + y * y)
    }

    func normalized() -> Vector2 {
      let len = length
      guard len > 0 else { return .zero }
      return Vector2(
        x: x / len,
        y: y / len,
      )
    }
}
