import Accelerate
import Foundation

public func createVImageBuffer(
  data: UnsafeMutableRawPointer,
  size: Size<Int>,
  bufferInfo: BufferInfo
) -> vImage_Buffer? {
  return vImage_Buffer(
    data: data,
    height: vImagePixelCount(size.height),
    width: vImagePixelCount(size.width),
    rowBytes: size.width * bufferInfo.bytesPerPixel
  )
}

public func copyVImageBuffer(
  _ buffer: inout vImage_Buffer, to pixelBuffer: inout CVPixelBuffer, bufferInfo: BufferInfo
) -> CVPixelBuffer? {
  var cgImageFormat = vImage_CGImageFormat(
    bitsPerComponent: UInt32(bufferInfo.bitsPerComponent),
    bitsPerPixel: UInt32(bufferInfo.bitsPerPixel),
    colorSpace: Unmanaged.passRetained(bufferInfo.colorSpace),
    bitmapInfo: bufferInfo.bitmapInfo,
    version: 0,
    decode: nil,
    renderingIntent: .defaultIntent
  )
  guard let cvImageFormat = vImageCVImageFormat_CreateWithCVPixelBuffer(pixelBuffer)?.takeRetainedValue() else {
    return nil
  }
  vImageCVImageFormat_SetColorSpace(cvImageFormat, bufferInfo.colorSpace)
  let copyError = vImageBuffer_CopyToCVPixelBuffer(
    &buffer,
    &cgImageFormat,
    pixelBuffer,
    cvImageFormat,
    nil,
    vImage_Flags(kvImageNoFlags)
  )
  if copyError != kvImageNoError {
    return nil
  }
  return pixelBuffer
}
