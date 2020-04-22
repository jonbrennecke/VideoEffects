import AVFoundation

public struct EffectConfig {
  public struct ColorControls {
    let brightness: Double
    let saturation: Double
    let contrast: Double

    public init(brightness: Double, saturation: Double, contrast: Double) {
      self.brightness = brightness
      self.saturation = saturation
      self.contrast = contrast
    }
    
    public static let grayscale = ColorControls(brightness: 0, saturation: 0, contrast: 1)
  }

  let colorControls: ColorControls
  let aspectRatio: CGSize?
  let timeRange: CMTimeRange?
  let layer: CALayer?

  public init() {
    colorControls = ColorControls(brightness: 0, saturation: 1, contrast: 1)
    aspectRatio = nil
    timeRange = nil
    layer = nil
  }

  private init(colorControls: ColorControls, aspectRatio: CGSize?, timeRange: CMTimeRange?, layer: CALayer?) {
    self.colorControls = colorControls
    self.aspectRatio = aspectRatio
    self.timeRange = timeRange
    self.layer = layer
  }

  public func setColorControls(_ colorControls: ColorControls) -> Self {
    return Self(colorControls: colorControls, aspectRatio: aspectRatio, timeRange: timeRange, layer: layer)
  }

  public func setAspectRatio(_ aspectRatio: CGSize) -> Self {
    return Self(colorControls: colorControls, aspectRatio: aspectRatio, timeRange: timeRange, layer: layer)
  }

  public func setTimeRange(_ timeRange: CMTimeRange) -> Self {
    return Self(colorControls: colorControls, aspectRatio: aspectRatio, timeRange: timeRange, layer: layer)
  }

  public func setLayer(_ layer: CALayer) -> Self {
    return Self(colorControls: colorControls, aspectRatio: aspectRatio, timeRange: timeRange, layer: layer)
  }
}
