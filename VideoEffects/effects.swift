import AVFoundation

public protocol Effect {
  func apply(exportSession: AVAssetExportSession, videoComposition: inout AVMutableVideoComposition)
}

public struct TrimEffect {
  public let range: CMTimeRange

  public init(range: CMTimeRange) {
    self.range = range
  }
}

extension TrimEffect: Effect {
  public func apply(exportSession: AVAssetExportSession, videoComposition _: inout AVMutableVideoComposition) {
    exportSession.timeRange = range
  }
}

public struct CropEffect {
  public let aspectRatio: CGSize

  public init(aspectRatio: CGSize) {
    self.aspectRatio = aspectRatio
  }
}

extension CropEffect: Effect {
  public func apply(exportSession: AVAssetExportSession, videoComposition composition: inout AVMutableVideoComposition) {
    guard let videoTrack = exportSession.asset.tracks(withMediaType: .video).first else {
      return
    }
    let videoTrackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.layerInstructions = [
      videoTrackInstruction,
    ]
    instruction.enablePostProcessing = true
    instruction.timeRange = videoTrack.timeRange

    // dimensions are reversed if video is in portrait orientation
    // videoTrack.naturalSize.applying(videoTrack.preferredTransform)
    // CGSize(width: abs(size.width), height: abs(size.height))
    let aspectRatio = self.aspectRatio.width / self.aspectRatio.height
    let height = videoTrack.naturalSize.height
    let width = height * aspectRatio
    composition.renderSize = CGSize(width: width, height: height)
    composition.frameDuration = CMTimeMake(value: 1, timescale: CMTimeScale(videoTrack.nominalFrameRate))
    composition.instructions = [instruction]
    exportSession.videoComposition = composition
  }
}

public struct ColorControlsEffect {
  let brightness: Double
  let saturation: Double
  let contrast: Double

  public init(brightness: Double, saturation: Double, contrast: Double) {
    self.brightness = brightness
    self.saturation = saturation
    self.contrast = contrast
  }
}

extension ColorControlsEffect: Effect {
  public func apply(exportSession: AVAssetExportSession, videoComposition _: inout AVMutableVideoComposition) {
    guard let videoTrack = exportSession.asset.tracks(withMediaType: .video).first else {
      return
    }
    if let compositor = exportSession.customVideoCompositor as? Compositor {
      compositor.filter = ColorControlsCompositorFilter(
        videoTrack: videoTrack.trackID, brightness: brightness, saturation: saturation, contrast: contrast
      )
    }
  }
}

public struct LayerEffect {
  let effectLayer = CALayer()
  let parentLayer = CALayer()
  let videoLayer = CALayer()

  public init(layer: CALayer) {
    effectLayer.addSublayer(layer)
  }
}

extension LayerEffect: Effect {
  public func apply(exportSession: AVAssetExportSession, videoComposition: inout AVMutableVideoComposition) {
    let frame = CGRect(origin: .zero, size: videoComposition.renderSize) // TODO: applying transform
    parentLayer.isGeometryFlipped = true
    parentLayer.frame = frame
    effectLayer.frame = frame
    videoLayer.frame = frame
    parentLayer.addSublayer(videoLayer)
    parentLayer.addSublayer(effectLayer)
    parentLayer.display()
    videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayers: [videoLayer], in: parentLayer)
    exportSession.videoComposition = videoComposition
  }
}

public struct AudioEffect {
  public init() {
    // TODO: enable/disable audio track
  }
}

extension AudioEffect: Effect {
  public func apply(exportSession: AVAssetExportSession, videoComposition _: inout AVMutableVideoComposition) {
    // TODO:
  }
}
