import AVFoundation
import CoreImage
import ImageUtils
import Metal

public class Compositor: NSObject, AVVideoCompositing {
  private enum VideoCompositionRequestError: Error {
    case failedToComposePixelBuffer
  }

  private var renderingQueue = DispatchQueue(label: "com.jonbrennecke.Compositor.renderingQueue")
  private var renderContext: AVVideoCompositionRenderContext?

  private lazy var context: CIContext! = {
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("Failed to get Metal device")
    }
    return CIContext(mtlDevice: device, options: [CIContextOption.workingColorSpace: NSNull()])
  }()

  public var filter: CompositorFilter? = DefaultFilter()

  // MARK: - AVVideoCompositing implementation

  public var sourcePixelBufferAttributes = [
    kCVPixelBufferPixelFormatTypeKey: [kCVPixelFormatType_32BGRA],
  ] as [String: Any]?

  public var requiredPixelBufferAttributesForRenderContext = [
    kCVPixelBufferPixelFormatTypeKey: [kCVPixelFormatType_32BGRA],
  ] as [String: Any]

  var shouldCancelAllRequests: Bool = false

  public func renderContextChanged(_ newContext: AVVideoCompositionRenderContext) {
    renderingQueue.sync { [weak self] in
      self?.renderContext = newContext
    }
  }

  public func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
    autoreleasepool {
      renderingQueue.async { [weak self] in
        guard let strongSelf = self else { return }
        if strongSelf.shouldCancelAllRequests {
          return request.finishCancelledRequest()
        }
        if let pixelBuffer = strongSelf.composePixelBuffer(with: request) {
          request.finish(withComposedVideoFrame: pixelBuffer)
        } else {
          // at least try to generate a blank pixel buffer
          if let pixelBuffer = strongSelf.renderContext?.newPixelBuffer() {
            request.finish(withComposedVideoFrame: pixelBuffer)
            return
          }
          request.finish(with: VideoCompositionRequestError.failedToComposePixelBuffer)
        }
      }
    }
  }

  public func cancelAllPendingVideoCompositionRequests() {
    renderingQueue.sync { shouldCancelAllRequests = true }
    renderingQueue.async { [weak self] in
      self?.shouldCancelAllRequests = false
    }
  }

  // MARK: - Utilities

  private func composePixelBuffer(with request: AVAsynchronousVideoCompositionRequest) -> CVPixelBuffer? {
    return autoreleasepool {
      guard
        let outputPixelBuffer = renderContext?.newPixelBuffer()
      else {
        return nil
      }
      if let effectImage = filter?.renderImage(with: request) {
        context.render(
          effectImage,
          to: outputPixelBuffer,
          bounds: effectImage.extent,
          colorSpace: nil
        )
      }
      return outputPixelBuffer
    }
  }
}

public protocol CompositorFilter {
  mutating func renderImage(with request: AVAsynchronousVideoCompositionRequest) -> CIImage?
}

struct DefaultFilter: CompositorFilter {
  mutating func renderImage(with request: AVAsynchronousVideoCompositionRequest) -> CIImage? {
    guard
      let trackID = request.sourceTrackIDs.first,
      let pixelBuffer = request.sourceFrame(byTrackID: trackID.int32Value as CMPersistentTrackID)
    else {
      return nil
    }
    return ImageBuffer(cvPixelBuffer: pixelBuffer).makeCIImage()
  }
}
