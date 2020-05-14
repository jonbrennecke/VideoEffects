import AVFoundation
import CoreImage
import ImageUtils

public class ColorControlsFilter {
  public var brightness: Double
  public var saturation: Double
  public var contrast: Double
  public var exposure: Double
  public var hue: Double

  public var videoTrack: CMPersistentTrackID?

  public init(
    brightness: Double = 0.0,
    saturation: Double = 1.0,
    contrast: Double = 1.0,
    exposure: Double = 0.0,
    hue: Double = 0.0
  ) {
    self.brightness = brightness
    self.saturation = saturation
    self.contrast = contrast
    self.exposure = exposure
    self.hue = hue
  }

  public static let grayscale = ColorControlsFilter(brightness: 0, saturation: 0, contrast: 1)

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

  private func applyColorControlsFilter(image: CIImage) -> CIImage? {
    guard let filter = colorControlsFilter else {
      return nil
    }
    filter.setValue(brightness, forKey: kCIInputBrightnessKey)
    filter.setValue(saturation, forKey: kCIInputSaturationKey)
    filter.setValue(contrast, forKey: kCIInputContrastKey)
    filter.setValue(image, forKey: kCIInputImageKey)
    return filter.outputImage
  }

  private func applyHueAdjustFilter(image: CIImage) -> CIImage? {
    guard let filter = hueAdjustFilter else {
      return nil
    }
    filter.setValue(hue, forKey: kCIInputAngleKey)
    filter.setValue(image, forKey: kCIInputImageKey)
    return filter.outputImage
  }

  private func applyExposureAdjustFilter(image: CIImage) -> CIImage? {
    guard let filter = exposureAdjustFilter else {
      return nil
    }
    filter.setValue(exposure, forKey: kCIInputEVKey)
    filter.setValue(image, forKey: kCIInputImageKey)
    return filter.outputImage
  }
}

extension ColorControlsFilter: CompositorFilter {
  public func renderFilter(with image: CIImage, request: AVAsynchronousVideoCompositionRequest) -> CIImage? {
    guard
      let trackID = videoTrack ?? request.sourceTrackIDs.first?.int32Value as CMPersistentTrackID?,
      let pixelBuffer = request.sourceFrame(byTrackID: trackID)
    else {
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
