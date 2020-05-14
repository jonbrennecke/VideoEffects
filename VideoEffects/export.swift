import AVFoundation

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
  effects: EffectConfig,
  config: ExportConfig,
  resultHandler: @escaping (Result<URL, ExportError>) -> Void
) {
  guard let exportSession = AVAssetExportSession(asset: asset, presetName: config.presetName) else {
    return resultHandler(.failure(.invalidAsset))
  }
  exportSession.outputFileType = config.outputFileType
  exportSession.outputURL = config.outputURL

  let composition = AVMutableVideoComposition()
  composition.customVideoCompositorClass = Compositor.self
  if let videoTrack = exportSession.asset.tracks(withMediaType: .video).first {
    let videoTrackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.layerInstructions = [
      videoTrackInstruction,
    ]
    instruction.enablePostProcessing = true
    instruction.timeRange = videoTrack.timeRange

    if let aspectRatioSize = effects.aspectRatio {
      // dimensions are reversed if video is in portrait orientation
      // videoTrack.naturalSize.applying(videoTrack.preferredTransform)
      // CGSize(width: abs(size.width), height: abs(size.height))
      let aspectRatio = aspectRatioSize.width / aspectRatioSize.height
      let height = videoTrack.naturalSize.height
      let width = height * aspectRatio
      composition.renderSize = CGSize(width: width, height: height)
    } else {
      composition.renderSize = videoTrack.naturalSize
    }

    composition.frameDuration = CMTimeMake(value: 1, timescale: CMTimeScale(videoTrack.nominalFrameRate))
    composition.instructions = [instruction]
    exportSession.videoComposition = composition
    if let compositor = exportSession.customVideoCompositor as? Compositor {
      compositor.filters = effects.filters
    }

    if let layer = effects.layer {
      let effectLayer = CALayer()
      let parentLayer = CALayer()
      let videoLayer = CALayer()
      effectLayer.addSublayer(layer)
      let frame = CGRect(origin: .zero, size: composition.renderSize) // TODO: applying transform
      parentLayer.isGeometryFlipped = true
      parentLayer.frame = frame
      effectLayer.frame = frame
      videoLayer.frame = frame
      parentLayer.addSublayer(videoLayer)
      parentLayer.addSublayer(effectLayer)
      parentLayer.display()
      composition
        .animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayers: [videoLayer], in: parentLayer)
      exportSession.videoComposition = composition
    }

    exportSession.timeRange = effects.timeRange ?? CMTimeRange(start: .zero, duration: .positiveInfinity)
  }

  try? FileManager.default.removeItem(at: config.outputURL)
  exportSession.exportAsynchronously {
    if exportSession.status != AVAssetExportSession.Status.completed {
      return resultHandler(.failure(.exportFailed))
    }
    resultHandler(.success(config.outputURL))
  }
}
