public struct Rectangle<T: Numeric> {
  let origin: Point2D<T>
  let size: Size<T>

  var x: T { return origin.x }
  var y: T { return origin.y }
  var height: T { return size.height }
  var width: T { return size.width }

  init(x: T, y: T, width: T, height: T) {
    origin = Point2D(x: x, y: y)
    size = Size(width: width, height: height)
  }

  init(origin: Point2D<T>, size: Size<T>) {
    self.origin = origin
    self.size = size
  }
}

extension Rectangle where T: Comparable & SignedInteger {
  internal func forEach(_ callback: (Point2D<T>) -> Void) {
    for y in stride(from: y, to: y + height, by: 1) {
      for x in stride(from: x, to: x + width, by: 1) {
        callback(Point2D(x: x, y: y))
      }
    }
  }
}
