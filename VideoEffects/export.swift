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
  effects: [Effect],
  config: ExportConfig,
  resultHandler: @escaping (Result<URL, ExportError>) -> Void
) {
  DispatchQueue.main.async {
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
}
