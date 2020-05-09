import AVFoundation

public struct EffectConfig {
  public struct ColorControls {
    public static let defaultBrightness: Double = 0.0
    public static let defaultSaturation: Double = 1.0
    public static let defaultContrast: Double = 1.0
    public static let defaultExposure: Double = 0.0
    public static let defaultHue: Double = 0.0

    public var brightness: Double = defaultBrightness
    public var saturation: Double = defaultSaturation
    public var contrast: Double = defaultContrast
    public var exposure: Double = defaultExposure
    public var hue: Double = defaultHue

    public init(
      brightness: Double = defaultBrightness,
      saturation: Double = defaultSaturation,
      contrast: Double = defaultContrast,
      exposure: Double = defaultExposure,
      hue: Double = defaultHue
    ) {
      self.brightness = brightness
      self.saturation = saturation
      self.contrast = contrast
      self.exposure = exposure
      self.hue = hue
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
