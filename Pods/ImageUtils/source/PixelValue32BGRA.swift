import Foundation

public struct PixelValue32BGRA {
  public let blue: UInt8
  public let green: UInt8
  public let red: UInt8
  public let alpha: UInt8

  public init(blue: UInt8, green: UInt8, red: UInt8, alpha: UInt8) {
    self.blue = blue
    self.green = green
    self.red = red
    self.alpha = alpha
  }

  // converts to grayscale (ignoring alpha)
  // reference: https://en.wikipedia.org/wiki/Luma_%28video%29
  public func asGrayScale() -> UInt8 {
    let floatValue: Float = Float(red) * 0.2989 + Float(green) * 0.5870 + Float(blue) * 0.1140
    return UInt8(exactly: clamp(floatValue, min: 0, max: 255).rounded()) ?? 0
  }

  public static let red = PixelValue32BGRA(blue: 0, green: 0, red: 0xFF, alpha: 0xFF)
  public static let blue = PixelValue32BGRA(blue: 0xFF, green: 0, red: 0, alpha: 0xFF)
  public static let green = PixelValue32BGRA(blue: 0, green: 0xFF, red: 0, alpha: 0xFF)
  public static let black = PixelValue32BGRA(blue: 0, green: 0, red: 0, alpha: 0xFF)
  public static let white = PixelValue32BGRA(blue: 0xFF, green: 0xFF, red: 0xFF, alpha: 0xFF)
}
