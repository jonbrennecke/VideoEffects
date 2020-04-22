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

public enum ExportError: Error {
  case invalidAsset
  case exportFailed
}

public struct ExportConfig {
  let presetName: String
  let outputFileType: AVFileType
  let outputURL: URL

  public init(presetName: String, outputFileType: AVFileType, outputURL: URL) {
    self.presetName = presetName
    self.outputFileType = outputFileType
    self.outputURL = outputURL
  }

  public static func defaultConfig() throws -> ExportConfig {
    return try Builder().build()
  }

  public struct Builder {
    let presetName: String
    let outputFileType: AVFileType
    let outputURL: URL?

    public init(presetName: String, outputFileType: AVFileType, outputURL: URL?) {
      self.presetName = presetName
      self.outputFileType = outputFileType
      self.outputURL = outputURL
    }

    public init() {
      presetName = AVAssetExportPresetMediumQuality
      outputFileType = .mov
      outputURL = nil
    }

    public func setOutputFileType(_ outputFileType: AVFileType) -> Builder {
      return Builder(presetName: presetName, outputFileType: outputFileType, outputURL: outputURL)
    }

    public func setOutputURL(_ outputURL: URL) -> Builder {
      return Builder(presetName: presetName, outputFileType: outputFileType, outputURL: outputURL)
    }

    public func setPresetName(_ presetName: String) -> Builder {
      return Builder(presetName: presetName, outputFileType: outputFileType, outputURL: outputURL)
    }

    public func build() throws -> ExportConfig {
      let url = try outputURL ?? createTemporaryUrl(for: outputFileType)
      return ExportConfig(presetName: presetName, outputFileType: outputFileType, outputURL: url)
    }
  }
}

public func export(
  asset: AVAsset,
  effects: [Effect],
  config: ExportConfig,
  resultHandler: @escaping (Result<URL, ExportError>) -> Void
) {
  guard let exportSession = AVAssetExportSession(asset: asset, presetName: config.presetName) else {
    return resultHandler(.failure(.invalidAsset))
  }
  exportSession.outputFileType = config.outputFileType
  exportSession.outputURL = config.outputURL

  var composition = AVMutableVideoComposition()
  composition.customVideoCompositorClass = Compositor.self
  if let videoTrack = exportSession.asset.tracks(withMediaType: .video).first {
    let videoTrackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.layerInstructions = [
      videoTrackInstruction,
    ]
    instruction.enablePostProcessing = true
    instruction.timeRange = videoTrack.timeRange
    composition.renderSize = videoTrack.naturalSize
    composition.frameDuration = CMTimeMake(value: 1, timescale: CMTimeScale(videoTrack.nominalFrameRate))
    composition.instructions = [instruction]
    exportSession.videoComposition = composition

    // TODO: collect errors from effects
    effects.forEach { $0.apply(exportSession: exportSession, videoComposition: &composition) }
  }

  try? FileManager.default.removeItem(at: config.outputURL)
  exportSession.exportAsynchronously {
    if exportSession.status != AVAssetExportSession.Status.completed {
      return resultHandler(.failure(.exportFailed))
    }
    resultHandler(.success(config.outputURL))
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
