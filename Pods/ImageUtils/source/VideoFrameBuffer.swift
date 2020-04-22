import AVFoundation

public struct VideoFrameBuffer {
  public let pixelBuffer: PixelBuffer
  public let presentationTime: CMTime

  public var size: Size<Int> {
    return pixelBuffer.size
  }

  public init(pixelBuffer: PixelBuffer, presentationTime: CMTime) {
    self.pixelBuffer = pixelBuffer
    self.presentationTime = presentationTime
  }
}
