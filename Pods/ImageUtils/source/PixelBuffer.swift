import AVFoundation
import CoreImage

public struct PixelBuffer {
  public let buffer: CVPixelBuffer

  public init(pixelBuffer buffer: CVPixelBuffer) {
    self.buffer = buffer
  }

  public init(depthData: AVDepthData) {
    let pixelBuffer = depthData.depthDataMap
    self.init(pixelBuffer: pixelBuffer)
  }

  public init?(sampleBuffer: CMSampleBuffer) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) as CVPixelBuffer? else {
      return nil
    }
    self.init(pixelBuffer: pixelBuffer)
  }

  public func withLockedBuffer<R>(_ fn: () -> R) -> R {
    return withLockedBaseAddress(buffer) { _ in
      fn()
    }
  }

  public var size: Size<Int> {
    return withLockedBuffer {
      pixelSizeOf(buffer: buffer)
    }
  }

  public var bytesPerRow: Int {
    return withLockedBuffer {
      CVPixelBufferGetBytesPerRow(buffer)
    }
  }

  public var pixelFormatType: OSType {
    return withLockedBuffer {
      CVPixelBufferGetPixelFormatType(buffer)
    }
  }

  public var bufferInfo: BufferInfo {
    return BufferInfo(pixelFormatType: pixelFormatType)
  }

  public func withDataPointer<R>(_ fn: (UnsafeRawPointer) -> R) -> R {
    return withLockedBuffer {
      let rawPtr = CVPixelBufferGetBaseAddress(buffer)
      return fn(rawPtr!)
    }
  }

  public func withMutableDataPointer<R>(_ fn: (UnsafeMutableRawPointer) -> R) -> R {
    return withLockedBuffer {
      let rawPtr = CVPixelBufferGetBaseAddress(buffer)
      return fn(rawPtr!)
    }
  }

  public func makeIterator<T>() -> PixelBufferIterator<T> {
    return PixelBufferIterator(pixelBuffer: self)
  }
}
