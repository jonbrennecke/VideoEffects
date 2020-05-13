import AVFoundation
import CoreImage
import ImageUtils

struct ColorControlsCompositorFilter {
  let brightness: Double
  let saturation: Double
  let contrast: Double
  let exposure: Double
  let hue: Double

  let videoTrack: CMPersistentTrackID

  public init(
    videoTrack: CMPersistentTrackID,
    brightness: Double,
    saturation: Double,
    contrast: Double,
    exposure: Double,
    hue: Double
  ) {
    self.videoTrack = videoTrack
    self.brightness = brightness
    self.saturation = saturation
    self.contrast = contrast
    self.exposure = exposure
    self.hue = hue
  }

  private lazy var colorControlsFilter: CIFilter? = {
    guard let filter = CIFilter(name: "CIColorControls") else {
      return nil
    }
    filter.setDefaults()
    return filter
  }()

  private lazy var exposureAdjustFilter: CIFilter? = {
    guard let filter = CIFilter(name: "CIExposureAdjust") else {
      return nil
    }
    filter.setDefaults()
    return filter
  }()

  private lazy var hueAdjustFilter: CIFilter? = {
    guard let filter = CIFilter(name: "CIHueAdjust") else {
      return nil
    }
    filter.setDefaults()
    return filter
  }()

  private mutating func applyColorControlsFilter(image: CIImage) -> CIImage? {
    guard let filter = colorControlsFilter else {
      return nil
    }
    filter.setValue(brightness, forKey: kCIInputBrightnessKey)
    filter.setValue(saturation, forKey: kCIInputSaturationKey)
    filter.setValue(contrast, forKey: kCIInputContrastKey)
    filter.setValue(image, forKey: kCIInputImageKey)
    return filter.outputImage
  }

  private mutating func applyHueAdjustFilter(image: CIImage) -> CIImage? {
    guard let filter = hueAdjustFilter else {
      return nil
    }
    filter.setValue(hue, forKey: kCIInputAngleKey)
    filter.setValue(image, forKey: kCIInputImageKey)
    return filter.outputImage
  }

  private mutating func applyExposureAdjustFilter(image: CIImage) -> CIImage? {
    guard let filter = exposureAdjustFilter else {
      return nil
    }
    filter.setValue(exposure, forKey: kCIInputEVKey)
    filter.setValue(image, forKey: kCIInputImageKey)
    return filter.outputImage
  }
}

extension ColorControlsCompositorFilter: CompositorFilter {
  mutating func renderImage(with request: AVAsynchronousVideoCompositionRequest) -> CIImage? {
    guard let pixelBuffer = request.sourceFrame(byTrackID: videoTrack) else {
      return nil
    }
    let imageBuffer = ImageBuffer(cvPixelBuffer: pixelBuffer)
    guard
      let image = imageBuffer.makeCIImage(),
      let imageA = applyColorControlsFilter(image: image),
      let imageB = applyExposureAdjustFilter(image: imageA),
      let outputImage = applyHueAdjustFilter(image: imageB)
    else {
      return nil
    }
    return outputImage
  }
}
