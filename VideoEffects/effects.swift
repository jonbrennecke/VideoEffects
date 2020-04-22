import AVFoundation

public protocol Effect {
  func apply(exportSession: AVAssetExportSession)
}

public struct TrimEffect {
  public let range: CMTimeRange

  public init(range: CMTimeRange) {
    self.range = range
  }
}

extension TrimEffect: Effect {
  public func apply(exportSession: AVAssetExportSession) {
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
  public func apply(exportSession: AVAssetExportSession) {
    guard let videoTrack = exportSession.asset.tracks(withMediaType: .video).first else {
      return
    }
    let aspectRatio = self.aspectRatio.width / self.aspectRatio.height

    // dimensions are reversed if video is in portrait orientation
    let height = videoTrack.naturalSize.height
    let width = height * aspectRatio

    let composition = AVMutableVideoComposition()
    composition.renderSize = CGSize(width: width, height: height)
    composition.frameDuration = CMTimeMake(value: 1, timescale: CMTimeScale(videoTrack.nominalFrameRate))

    // TODO: this has nothing to do with cropping, should be applied elsewhere
    composition.customVideoCompositorClass = Compositor.self

    let videoTrackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.layerInstructions = [
      videoTrackInstruction,
    ]
    instruction.enablePostProcessing = true // TODO: only if it uses a compositor
    instruction.timeRange = videoTrack.timeRange
    composition.instructions = [instruction]
    exportSession.videoComposition = composition
  }
}

public func applyEffects(exportSession: AVAssetExportSession, effects: [Effect]) {
  effects.forEach { $0.apply(exportSession: exportSession) }
}

public struct ColorControlsFilterEffect {
  let brightness: Double
  let saturation: Double
  let contrast: Double

  public init(brightness: Double, saturation: Double, contrast: Double) {
    self.brightness = brightness
    self.saturation = saturation
    self.contrast = contrast
  }
}

extension ColorControlsFilterEffect: Effect {
  public func apply(exportSession: AVAssetExportSession) {
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
