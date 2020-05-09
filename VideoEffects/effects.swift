import AVFoundation

public struct EffectConfig {
  public struct ColorControls {
    public var brightness: Double
    public var saturation: Double
    public var contrast: Double
    public var exposure: Double
    public var hue: Double

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

    public static let grayscale = ColorControls(brightness: 0, saturation: 0, contrast: 1)
  }

  public var colorControls: ColorControls
  public var aspectRatio: CGSize?
  public var timeRange: CMTimeRange?
  public var layer: CALayer?

  public init(
    colorControls: ColorControls = ColorControls(),
    aspectRatio: CGSize? = nil,
    timeRange: CMTimeRange? = nil,
    layer: CALayer? = nil
  ) {
    self.colorControls = colorControls
    self.aspectRatio = aspectRatio
    self.timeRange = timeRange
    self.layer = layer
  }
}
