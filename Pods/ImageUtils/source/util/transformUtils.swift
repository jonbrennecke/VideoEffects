import Accelerate
import AVFoundation

public func convertBGRAPixelBufferToGrayscale(pixelBuffer: PixelBuffer, pixelBufferPool: CVPixelBufferPool) -> PixelBuffer? {
  return pixelBuffer.withMutableDataPointer({ ptr -> PixelBuffer? in
    var sourceBuffer = vImage_Buffer(
      data: ptr,
      height: vImagePixelCount(pixelBuffer.size.height),
      width: vImagePixelCount(pixelBuffer.size.width),
      rowBytes: pixelBuffer.bytesPerRow
    )
    let destinationBufferInfo = BufferInfo(pixelFormatType: kCVPixelFormatType_OneComponent8)
    let destinationBytesPerRow = pixelBuffer.size.width * destinationBufferInfo.bytesPerPixel
    let destinationTotalBytes = pixelBuffer.size.height * destinationBytesPerRow

    var destinationBuffer = vImage_Buffer()
    let initError = vImageBuffer_Init(
      &destinationBuffer,
      vImagePixelCount(pixelBuffer.size.height),
      vImagePixelCount(pixelBuffer.size.width),
      UInt32(destinationBufferInfo.bitsPerPixel),
      vImage_Flags(kvImageNoFlags)
    )
    if initError != kvImageNoError {
      return nil
    }
    defer {
      free(destinationBuffer.data)
    }

    let redCoeff = Float(0.2126)
    let greenCoeff = Float(0.7152)
    let blueCoeff = Float(0.0722)
    let divisor = Int32(0x1000)
    var coefficientsMatrix = [
      Int16(redCoeff * Float(divisor)),
      Int16(greenCoeff * Float(divisor)),
      Int16(blueCoeff * Float(divisor)),
    ]
    var preBias: [Int16] = [0, 0, 0, 0]
    let postBias = Int32(0)

    let error = vImageMatrixMultiply_ARGB8888ToPlanar8(
      &sourceBuffer,
      &destinationBuffer,
      &coefficientsMatrix,
      0x1000,
      &preBias,
      postBias,
      vImage_Flags(kvImageNoFlags)
    )
    if error != kvImageNoError {
      return nil
    }
    guard var destinationPixelBuffer = createPixelBuffer(with: pixelBufferPool) else {
      return nil
    }
    guard case .some = copyVImageBuffer(
      &destinationBuffer,
      to: &destinationPixelBuffer,
      bufferInfo: destinationBufferInfo
    ) else {
      return nil
    }
    return PixelBuffer(pixelBuffer: destinationPixelBuffer)
  })
}

public func convertDisparityOrDepthPixelBufferToUInt8(
  pixelBuffer: PixelBuffer, pixelBufferPool: CVPixelBufferPool, bounds: ClosedRange<Float>
) -> PixelBuffer? {
  return pixelBuffer.withMutableDataPointer({ ptr -> PixelBuffer? in
    var sourceBuffer = vImage_Buffer(
      data: ptr,
      height: vImagePixelCount(pixelBuffer.size.height),
      width: vImagePixelCount(pixelBuffer.size.width),
      rowBytes: pixelBuffer.bytesPerRow
    )
    let destinationBufferInfo = BufferInfo(pixelFormatType: kCVPixelFormatType_OneComponent8)
    let destinationBytesPerRow = pixelBuffer.size.width * destinationBufferInfo.bytesPerPixel
    let destinationTotalBytes = pixelBuffer.size.height * destinationBytesPerRow

    var destinationBuffer = vImage_Buffer()
    let initError = vImageBuffer_Init(
      &destinationBuffer,
      vImagePixelCount(pixelBuffer.size.height),
      vImagePixelCount(pixelBuffer.size.width),
      UInt32(destinationBufferInfo.bitsPerPixel),
      vImage_Flags(kvImageNoFlags)
    )
    if initError != kvImageNoError {
      return nil
    }
    defer {
      free(destinationBuffer.data)
    }
    let is16BitData =
      pixelBuffer.pixelFormatType == kCVPixelFormatType_DisparityFloat16
      || pixelBuffer.pixelFormatType == kCVPixelFormatType_DepthFloat16
    var error: vImage_Error?
    if is16BitData {
      error = vImageConvert_Planar16FtoPlanar8(
        &sourceBuffer,
        &destinationBuffer,
        vImage_Flags(kvImageNoFlags)
      )
    } else {
      error = vImageConvert_PlanarFtoPlanar8(
        &sourceBuffer,
        &destinationBuffer,
        bounds.upperBound,
        bounds.lowerBound,
        vImage_Flags(kvImageNoFlags)
      )
    }
    if error != kvImageNoError {
      return nil
    }
    guard var destinationPixelBuffer = createPixelBuffer(with: pixelBufferPool) else {
      return nil
    }
    guard case .some = copyVImageBuffer(
      &destinationBuffer,
      to: &destinationPixelBuffer,
      bufferInfo: destinationBufferInfo
    ) else {
      return nil
    }
    return PixelBuffer(pixelBuffer: destinationPixelBuffer)
  })
}
