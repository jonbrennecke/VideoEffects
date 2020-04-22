import Accelerate
import AVFoundation

public struct PixelBufferIterator<T> {
  public let pixelBuffer: PixelBuffer

  public var size: Size<Int> {
    return pixelBuffer.size
  }

  public func forEachPixel(in rect: Rectangle<Int>, _ callback: (T, Int) -> Void) {
    pixelBuffer.withDataPointer { rawPtr in
      let ptr = UnsafeMutablePointer<T>(OpaquePointer(rawPtr.assumingMemoryBound(to: T.self)))
      let bytesPerRow = pixelBuffer.bytesPerRow
      let pixelsPerRow = bytesPerRow / pixelBuffer.bufferInfo.bytesPerPixel
      rect.forEach { index2D in
        let index = (index2D.y - rect.y) * rect.width + (index2D.x - rect.x)
        let ptrIndex = index2D.y * pixelsPerRow + index2D.x
        let pixel = ptr[ptrIndex]
        callback(pixel, index)
      }
    }
  }

  public func forEachPixel(in size: Size<Int>, _ callback: (T, Int) -> Void) {
    return forEachPixel(in: Rectangle(origin: .zero(), size: size), callback)
  }

  public func forEachPixel(_ callback: (T, Int) -> Void) {
    return forEachPixel(in: pixelBuffer.size, callback)
  }

  public func getBytes() -> [UInt8] {
    let bytesPerPixel = pixelBuffer.bufferInfo.bytesPerPixel
    let length = pixelBuffer.size.width * pixelBuffer.size.height * bytesPerPixel
    var ret = [UInt8](repeating: 0, count: length)
    forEachPixel { pixel, i in
      let index = i * bytesPerPixel
      var pixel = pixel
      memcpy(&ret[index], &pixel, bytesPerPixel)
    }
    return ret
  }

  public func mapPixels<R: Numeric>(_ transform: (T) -> R) -> [R] {
    let length = pixelBuffer.size.width * pixelBuffer.size.height
    var ret = [R](repeating: 0, count: length)
    forEachPixel { pixel, i in
      ret[i] = transform(pixel)
    }
    return ret
  }

  public func map<R: Numeric>(
    pixelFormatType: OSType,
    pixelBufferPool: CVPixelBufferPool,
    transform: (T) -> R
  ) -> PixelBufferIterator<R>? {
    var pixels = mapPixels(transform)
    let destBufferInfo = BufferInfo(pixelFormatType: pixelFormatType)
    let destBytesPerRow = pixelBuffer.size.width * destBufferInfo.bytesPerPixel
    var destBuffer = vImage_Buffer(
      data: &pixels,
      height: vImagePixelCount(pixelBuffer.size.height),
      width: vImagePixelCount(pixelBuffer.size.width),
      rowBytes: destBytesPerRow
    )
    guard var destPixelBuffer = createPixelBuffer(with: pixelBufferPool) else {
      return nil
    }
    guard case .some = copyVImageBuffer(&destBuffer, to: &destPixelBuffer, bufferInfo: destBufferInfo) else {
      return nil
    }
    let buffer = PixelBuffer(pixelBuffer: destPixelBuffer)
    return PixelBufferIterator<R>(pixelBuffer: buffer)
  }
}

extension PixelBufferIterator where T: Numeric {
  public func getPixels() -> [T] {
    return mapPixels { px in px }
  }

  public func getPixels(in rect: Rectangle<Int>) -> [T] {
    let length = rect.width * rect.height
    var ret = [T](repeating: 0, count: length)
    forEachPixel(in: rect) { pixel, i in
      ret[i] = pixel
    }
    return ret
  }

  public func map(transform: (T) -> T) -> PixelBufferIterator<T>? {
    var pixels = mapPixels(transform)
    let destBufferInfo = BufferInfo(pixelFormatType: pixelBuffer.pixelFormatType)
    let destBytesPerRow = pixelBuffer.size.width * destBufferInfo.bytesPerPixel
    var destBuffer = vImage_Buffer(
      data: &pixels,
      height: vImagePixelCount(pixelBuffer.size.height),
      width: vImagePixelCount(pixelBuffer.size.width),
      rowBytes: destBytesPerRow
    )
    var destPixelBuffer = pixelBuffer.buffer
    guard case .some = copyVImageBuffer(&destBuffer, to: &destPixelBuffer, bufferInfo: destBufferInfo) else {
      return nil
    }
    let buffer = PixelBuffer(pixelBuffer: destPixelBuffer)
    return PixelBufferIterator(pixelBuffer: buffer)
  }
}

extension PixelBufferIterator where T: FloatingPoint {
  public func bounds() -> ClosedRange<T> {
    var min: T = T.greatestFiniteMagnitude
    var max: T = T.leastNonzeroMagnitude
    forEachPixel { x, _ in
      if x > max {
        max = x
      } else if x < min {
        min = x
      }
    }
    return min ... max
  }
}

extension PixelBufferIterator where T: FixedWidthInteger {
  public func bounds() -> ClosedRange<T> {
    var min: T = T.max
    var max: T = T.min
    forEachPixel { x, _ in
      if x > max {
        max = x
      } else if x < min {
        min = x
      }
    }
    return min ... max
  }
}
