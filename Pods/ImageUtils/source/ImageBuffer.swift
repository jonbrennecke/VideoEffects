import Accelerate
import AVFoundation
import CoreImage

public struct ImageBuffer {
  public let pixelBuffer: PixelBuffer

  public var size: Size<Int> {
    return pixelBuffer.size
  }

  public init(pixelBuffer: PixelBuffer) {
    self.pixelBuffer = pixelBuffer
  }

  public init(cvPixelBuffer buffer: CVPixelBuffer) {
    pixelBuffer = PixelBuffer(pixelBuffer: buffer)
  }

  public func makeVImageBuffer() -> vImage_Buffer {
    return pixelBuffer.withMutableDataPointer { ptr -> vImage_Buffer in
      vImage_Buffer(
        data: ptr,
        height: vImagePixelCount(size.height),
        width: vImagePixelCount(size.width),
        rowBytes: pixelBuffer.bytesPerRow
      )
    }
  }

  public func makeCGImage() -> CGImage? {
    var buffer = makeVImageBuffer()
    let bufferInfo = pixelBuffer.bufferInfo
    var cgImageFormat = vImage_CGImageFormat(
      bitsPerComponent: UInt32(bufferInfo.bitsPerComponent),
      bitsPerPixel: UInt32(bufferInfo.bitsPerPixel),
      colorSpace: Unmanaged.passRetained(bufferInfo.colorSpace),
      bitmapInfo: bufferInfo.bitmapInfo,
      version: 0,
      decode: nil,
      renderingIntent: .defaultIntent
    )
    var error: vImage_Error = kvImageNoError
    let image = vImageCreateCGImageFromBuffer(
      &buffer,
      &cgImageFormat,
      nil,
      nil,
      vImage_Flags(kvImageHighQualityResampling),
      &error
    )
    guard error == kvImageNoError else {
      return nil
    }
    return image?.takeRetainedValue()
  }

  public func makeCIImage() -> CIImage? {
    if let cgImage = makeCGImage() {
      return CIImage(cgImage: cgImage)
    }
    return nil
  }

  public func resize(
    to outputSize: Size<Int>,
    pixelBufferPool: CVPixelBufferPool,
    isGrayscale: Bool = false
  ) -> ImageBuffer? {
    let bufferInfo = pixelBuffer.bufferInfo
    var srcBuffer = makeVImageBuffer()

    // create an empty destination vImage_Buffer
    let destTotalBytes = outputSize.height * outputSize.width * bufferInfo.bytesPerPixel
    let destBytesPerRow = outputSize.width * bufferInfo.bytesPerPixel
    guard let destData = malloc(destTotalBytes) else {
      return nil
    }
    var destBuffer = vImage_Buffer(
      data: destData,
      height: vImagePixelCount(outputSize.height),
      width: vImagePixelCount(outputSize.width),
      rowBytes: destBytesPerRow
    )

    // scale
    let resizeFlags = vImage_Flags(kvImageHighQualityResampling)
    if isGrayscale {
      let error = vImageScale_Planar8(&srcBuffer, &destBuffer, nil, resizeFlags)
      if error != kvImageNoError {
        free(destData)
        return nil
      }
    } else {
      let error = vImageScale_ARGB8888(&srcBuffer, &destBuffer, nil, resizeFlags)
      if error != kvImageNoError {
        free(destData)
        return nil
      }
    }

    guard let destPixelBuffer = createPixelBuffer(with: pixelBufferPool) else {
      free(destData)
      return nil
    }

    // save vImageBuffer to CVPixelBuffer

    var cgImageFormat = vImage_CGImageFormat(
      bitsPerComponent: UInt32(bufferInfo.bitsPerComponent),
      bitsPerPixel: UInt32(bufferInfo.bitsPerPixel),
      colorSpace: Unmanaged.passRetained(bufferInfo.colorSpace),
      bitmapInfo: bufferInfo.bitmapInfo,
      version: 0,
      decode: nil,
      renderingIntent: .defaultIntent
    )

    guard let cvImageFormat = vImageCVImageFormat_CreateWithCVPixelBuffer(destPixelBuffer)?.takeRetainedValue() else {
      free(destData)
      return nil
    }
    vImageCVImageFormat_SetColorSpace(cvImageFormat, bufferInfo.colorSpace)

    let copyError = vImageBuffer_CopyToCVPixelBuffer(
      &destBuffer,
      &cgImageFormat,
      destPixelBuffer,
      cvImageFormat,
      nil,
      vImage_Flags(kvImageNoFlags)
    )

    if copyError != kvImageNoError {
      free(destData)
      return nil
    }
    free(destData)
    return ImageBuffer(cvPixelBuffer: destPixelBuffer)
  }
}
