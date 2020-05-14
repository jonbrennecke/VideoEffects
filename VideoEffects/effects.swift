import AVFoundation

public struct EffectConfig {
  public var aspectRatio: CGSize?
  public var timeRange: CMTimeRange?
  public var layer: CALayer?
  public var filters = [CompositorFilter]()

  public init(
    filters: [CompositorFilter] = [],
    aspectRatio: CGSize? = nil,
    timeRange: CMTimeRange? = nil,
    layer: CALayer? = nil
  ) {
    self.filters = filters
    self.aspectRatio = aspectRatio
    self.timeRange = timeRange
    self.layer = layer
  }
}
