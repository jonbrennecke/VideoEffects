import AVFoundation

public struct BufferInfo {
  public static let grayScaleUInt8 = BufferInfo(pixelFormatType: kCVPixelFormatType_OneComponent8)

  public let pixelFormatType: OSType

  public init(pixelFormatType: OSType) {
    self.pixelFormatType = pixelFormatType
  }

  public var bitmapInfo: CGBitmapInfo {
    switch pixelFormatType {
    case kCVPixelFormatType_32BGRA:
      return CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        .union(.byteOrder32Little)
    case kCVPixelFormatType_32RGBA:
      return CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
    case kCVPixelFormatType_DisparityFloat32,
         kCVPixelFormatType_DepthFloat32:
      return CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        .union(.floatComponents)
        .union(.byteOrder32Little)
    case kCVPixelFormatType_DisparityFloat16,
         kCVPixelFormatType_DepthFloat16:
      return CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        .union(.floatComponents)
        .union(.byteOrder16Little)
    case kCVPixelFormatType_OneComponent8:
      fallthrough
    default:
      return CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
    }
  }

  public var colorSpace: CGColorSpace {
    switch pixelFormatType {
    case kCVPixelFormatType_OneComponent8,
         kCVPixelFormatType_DisparityFloat16,
         kCVPixelFormatType_DepthFloat16,
         kCVPixelFormatType_DisparityFloat32,
         kCVPixelFormatType_DepthFloat32:
      return CGColorSpaceCreateDeviceGray()
    default:
      return CGColorSpaceCreateDeviceRGB()
    }
  }

  public var bytesPerPixel: Int {
    switch pixelFormatType {
    case kCVPixelFormatType_DisparityFloat16,
         kCVPixelFormatType_DepthFloat16:
      return MemoryLayout<UInt16>.size
    case kCVPixelFormatType_DisparityFloat32,
         kCVPixelFormatType_DepthFloat32:
      return MemoryLayout<Float32>.size
    case kCVPixelFormatType_OneComponent8:
      return MemoryLayout<UInt8>.size
    default:
      return MemoryLayout<Float32>.size
    }
  }

  public var bitsPerPixel: Int {
    return bytesPerPixel * 8
  }

  public var bytesPerComponent: Int {
    switch pixelFormatType {
    case kCVPixelFormatType_DisparityFloat16,
         kCVPixelFormatType_DepthFloat16:
      return MemoryLayout<UInt16>.size
    case kCVPixelFormatType_DisparityFloat32,
         kCVPixelFormatType_DepthFloat32:
      return MemoryLayout<Float32>.size
    case kCVPixelFormatType_OneComponent8:
      return MemoryLayout<UInt8>.size
    default:
      return MemoryLayout<UInt8>.size
    }
  }

  public var bitsPerComponent: Int {
    return bytesPerComponent * 8
  }
}
