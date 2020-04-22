public struct Point2D<T: Numeric> {
  let x: T
  let y: T

  static func zero() -> Point2D<T> {
    return Point2D(x: 0, y: 0)
  }
}

extension Point2D where T: Comparable {
  func isIn(rect: Rectangle<T>) -> Bool {
    return x >= rect.origin.x
      && y >= rect.origin.y
      && x <= rect.origin.x + rect.size.width
      && y <= rect.origin.y + rect.size.height
  }
}
