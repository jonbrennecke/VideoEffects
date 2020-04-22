import Accelerate
import CoreVideo

public func withLockedBaseAddress<T>(
  _ buffer: CVPixelBuffer,
  flags: CVPixelBufferLockFlags = .readOnly,
  _ callback: (CVPixelBuffer) -> T
) -> T {
  CVPixelBufferLockBaseAddress(buffer, flags)
  let ret = callback(buffer)
  CVPixelBufferUnlockBaseAddress(buffer, flags)
  return ret
}

internal func pixelSizeOf<T: Numeric>(buffer: CVPixelBuffer) -> Size<T> {
  return withLockedBaseAddress(buffer) { buffer in
    let width = CVPixelBufferGetWidth(buffer)
    let height = CVPixelBufferGetHeight(buffer)
    return Size<T>(width: T(exactly: width)!, height: T(exactly: height)!)
  }
}

public func createBuffer(
  data: UnsafeMutableRawPointer,
  size: Size<Int>,
  bytesPerRow: Int,
  pixelFormatType: OSType,
  releaseCallback: CVPixelBufferReleaseBytesCallback?
) -> CVPixelBuffer? {
  let attrs = [
    kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
    kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
  ] as CFDictionary
  var buffer: CVPixelBuffer!
  let status = CVPixelBufferCreateWithBytes(
    kCFAllocatorDefault,
    size.width,
    size.height,
    pixelFormatType,
    data,
    bytesPerRow,
    releaseCallback,
    nil,
    attrs,
    &buffer
  )
  guard status == kCVReturnSuccess else {
    return nil
  }
  return buffer
}

public func createCVPixelBufferPool(size: Size<Int>, pixelFormatType: OSType, count: Int = 1) -> CVPixelBufferPool? {
  let poolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey: count] as CFDictionary
  let bufferAttributes = [
//    kCVPixelBufferCGImageCompatibilityKey: true,
//    kCVPixelBufferCGBitmapContextCompatibilityKey: true,
    kCVPixelBufferPixelFormatTypeKey: pixelFormatType,
    kCVPixelBufferWidthKey: size.width,
    kCVPixelBufferHeightKey: size.height,
  ] as [String: Any] as CFDictionary
  var pool: CVPixelBufferPool!
  let status = CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes, bufferAttributes, &pool)
  if status != kCVReturnSuccess {
    return nil
  }
  return pool
}

public func createPixelBuffer(with pool: CVPixelBufferPool) -> CVPixelBuffer? {
  var destPixelBuffer: CVPixelBuffer!
  let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &destPixelBuffer)
  guard status == kCVReturnSuccess else {
    return nil
  }
  return destPixelBuffer
}

public func createPixelBuffer(
  data: UnsafeMutableRawPointer,
  size: Size<Int>,
  pool: CVPixelBufferPool,
  bufferInfo: BufferInfo
) -> PixelBuffer? {
  guard var vImageBuffer = createVImageBuffer(
    data: data,
    size: size,
    bufferInfo: bufferInfo
  ) else {
    return nil
  }
  guard var pixelBuffer = createPixelBuffer(with: pool) else {
    return nil
  }
  if case .some = copyVImageBuffer(&vImageBuffer, to: &pixelBuffer, bufferInfo: bufferInfo) {
    return PixelBuffer(pixelBuffer: pixelBuffer)
  }
  return nil
}
