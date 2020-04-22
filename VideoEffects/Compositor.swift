import AVFoundation
import CoreImage
import Metal

class Compositor: NSObject, AVVideoCompositing {
  private enum VideoCompositionRequestError: Error {
    case failedToComposePixelBuffer
  }

  private var renderingQueue = DispatchQueue(label: "com.jonbrennecke..renderingqueue")
  private var renderContext: AVVideoCompositionRenderContext?

  private lazy var context: CIContext! = {
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("Failed to get Metal device")
    }
    return CIContext(mtlDevice: device, options: [CIContextOption.workingColorSpace: NSNull()])
  }()

  // MARK: - AVVideoCompositing implementation

  var sourcePixelBufferAttributes = [
    kCVPixelBufferPixelFormatTypeKey: [kCVPixelFormatType_32BGRA],
  ] as [String: Any]?

  var requiredPixelBufferAttributesForRenderContext = [
    kCVPixelBufferPixelFormatTypeKey: [kCVPixelFormatType_32BGRA],
  ] as [String: Any]

  var shouldCancelAllRequests: Bool = false

  func renderContextChanged(_ newContext: AVVideoCompositionRenderContext) {
    renderingQueue.sync { [weak self] in
      self?.renderContext = newContext
    }
  }

  func startRequest(_ request: AVAsynchronousVideoCompositionRequest) {
    autoreleasepool {
      renderingQueue.async { [weak self] in
        guard let strongSelf = self else { return }
        if strongSelf.shouldCancelAllRequests {
          request.finishCancelledRequest()
          return
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

  func cancelAllPendingVideoCompositionRequests() {
    renderingQueue.sync { shouldCancelAllRequests = true }
    renderingQueue.async { [weak self] in
      self?.shouldCancelAllRequests = false
    }
  }

  // MARK: - Utilities

  private func composePixelBuffer(with _: AVAsynchronousVideoCompositionRequest) -> CVPixelBuffer? {
    return autoreleasepool {
      guard
        let outputPixelBuffer = renderContext?.newPixelBuffer()
      else {
        return nil
      }
//        request.sourceFrame(byTrackID: <#T##CMPersistentTrackID#>)
//        Apply effects here
//      context.render(
//        effectImage,
//        to: outputPixelBuffer,
//        bounds: effectImage.extent,
//        colorSpace: nil
//      )
      return outputPixelBuffer
    }
  }

  // MARK: - Filter

  struct Filter {
    
  }
}

protocol CompositorFilter {
  func apply(request: AVAsynchronousVideoCompositionRequest)
}

struct ColorControlsCompositorFilter {
  let brightness: Double
  let saturation: Double
  let contrast: Double
  let videoTrack: CMPersistentTrackID

  public init(videoTrack: CMPersistentTrackID, brightness: Double, saturation: Double, contrast: Double) {
    self.videoTrack = videoTrack
    self.brightness = brightness
    self.saturation = saturation
    self.contrast = contrast
  }
  
  private lazy var colorControlsFilter: CIFilter? = {
    guard let filter = CIFilter(name: "CIColorControls") else {
      return nil
    }
    filter.setDefaults()
    return filter
  }()
}

extension ColorControlsCompositorFilter : CompositorFilter {
  func apply(request: AVAsynchronousVideoCompositionRequest) {
    guard let pixelBuffer = request.sourceFrame(byTrackID: videoTrack) else {
      return
    }
//    let image = HSImageBuffer(pixelBuffer: videoPixelBuffer).makeCIImage(),
//    guard let depthBlurFilter = depthBlurEffectFilter else {
//      return nil
//    }
//
//    colorControlsFilter.setValue(brightness, forKey: kCIInputBrightnessKey)
//    colorControlsFilter.setValue(saturation, forKey: kCIInputSaturationKey)
//    colorControlsFilter.setValue(contrast, forKey: kCIInputContrastKey)
//    colorControlsFilter.setValue(image, forKey: kCIInputImageKey)
//    pixelBuffer
  }
}
