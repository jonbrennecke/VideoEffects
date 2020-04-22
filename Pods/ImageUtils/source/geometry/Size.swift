import CoreGraphics.CGBase

public struct Size<T: Numeric> {
  public let width: T
  public let height: T

  public init(width: T, height: T) {
    self.width = width
    self.height = height
  }
}

extension Size: Equatable where T: Equatable {}

extension Size where T: SignedInteger {
  public func cgSize() -> CGSize {
    return CGSize(width: Int(width), height: Int(height))
  }
}

extension Size where T: BinaryFloatingPoint {
  public func cgSize() -> CGSize {
    return CGSize(width: CGFloat(width), height: CGFloat(height))
  }
}

extension Size where T: Comparable & SignedInteger {
  internal func forEach(_ callback: (Point2D<T>) -> Void) {
    for x in stride(from: 0, to: width, by: 1) {
      for y in stride(from: 0, to: height, by: 1) {
        callback(Point2D(x: x, y: y))
      }
    }
  }
}

extension CGSize {
  public func integerSize<T: SignedInteger>() -> Size<T> {
    return Size<T>(width: T(width.rounded()), height: T(height.rounded()))
  }
}
