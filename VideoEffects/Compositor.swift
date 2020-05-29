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

  // MARK: - public vars

  public var filters = [CompositorFilter]()

  public var transform: CGAffineTransform = .identity

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
      // if there aren't any filters, just output the first video track
      if filters.count == 0 {
        guard
          let trackID = request.sourceTrackIDs.first,
          let pixelBuffer = request.sourceFrame(byTrackID: trackID.int32Value as CMPersistentTrackID)
        else {
          return nil
        }
        return pixelBuffer
      }

      guard
        let outputPixelBuffer = renderContext?.newPixelBuffer(),
        let image = ImageBuffer(cvPixelBuffer: outputPixelBuffer).makeCIImage()
      else {
        return nil
      }

      let outputImage = filters.reduce(into: image) { (img: inout CIImage, filter) in
        guard let renderedImage = filter.renderFilter(with: img, request: request) else {
          return
        }
        img = renderedImage
      }
      let transformedOutputImage = outputImage.transformed(by: transform)
      print(transformedOutputImage.extent)
      context.render(
        transformedOutputImage,
        to: outputPixelBuffer,
        bounds: transformedOutputImage.extent,
        colorSpace: nil
      )
      return outputPixelBuffer
    }
  }
}

public protocol CompositorFilter {
  var videoTrack: CMPersistentTrackID? { get set }
  func renderFilter(with image: CIImage, request: AVAsynchronousVideoCompositionRequest) -> CIImage?
}
