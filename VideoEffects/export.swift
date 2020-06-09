import AVFoundation
import UIKit.UIColor

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

private func createVideoComposition(withAsset asset: AVAsset) -> (AVComposition, AVMutableVideoComposition) {
  let composition = AVMutableComposition()
  let videoTracks = asset.tracks(withMediaType: .video)
  let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
  
  // Add video tracks
  let layerInstructions: [AVVideoCompositionLayerInstruction] = videoTracks.map { track in
    let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: track.trackID)
    try? compositionVideoTrack?.insertTimeRange(timeRange, of: track, at: .zero)
    let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
    layerInstruction.setTransform(track.preferredTransform, at: .zero)
    return layerInstruction
  }
  
  // Add audio track
  // TODO: audio track should be optional
  if
    let audioTrack = asset.tracks(withMediaType: .audio).first,
    let compositionAudioTrack = composition.addMutableTrack(
      withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid
    ) {
    try? compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
  }
  
  let instruction = AVMutableVideoCompositionInstruction()
  instruction.enablePostProcessing = true
  instruction.backgroundColor = UIColor.black.cgColor
  instruction.layerInstructions = layerInstructions
  instruction.timeRange = timeRange

  let videoComposition = AVMutableVideoComposition()
  if let firstVideoTrack = videoTracks.first {
    let transformedSize = firstVideoTrack.naturalSize.applying(firstVideoTrack.preferredTransform.inverted())
    videoComposition.renderSize = CGSize(width: abs(transformedSize.width), height: abs(transformedSize.height))
    videoComposition.frameDuration = CMTimeMake(value: 1, timescale: CMTimeScale(firstVideoTrack.nominalFrameRate))
  }
  videoComposition.customVideoCompositorClass = Compositor.self
  videoComposition.instructions = [instruction]
  return (composition, videoComposition)
}

public func export(
  asset: AVAsset,
  effects: EffectConfig,
  config: ExportConfig,
  resultHandler: @escaping (Result<URL, ExportError>) -> Void
) {
  let (composition, videoComposition) = createVideoComposition(withAsset: asset)
  guard let exportSession = AVAssetExportSession(asset: composition, presetName: config.presetName) else {
    return resultHandler(.failure(.invalidAsset))
  }
  exportSession.outputFileType = config.outputFileType
  exportSession.outputURL = config.outputURL
  exportSession.videoComposition = videoComposition
  if let compositor = exportSession.customVideoCompositor as? Compositor {
    compositor.filters = effects.filters
    if let videoTrack = asset.tracks(withMediaType: .video).first {
      compositor.transform = orientationTransform(forVideoTrack: videoTrack)
    }
  }
  if let layer = effects.layer {
    let effectLayer = CALayer()
    let parentLayer = CALayer()
    let videoLayer = CALayer()
    effectLayer.addSublayer(layer)
    let frame = CGRect(origin: .zero, size: videoComposition.renderSize) // TODO: applying transform
    parentLayer.isGeometryFlipped = true
    parentLayer.frame = frame
    effectLayer.frame = frame
    videoLayer.frame = frame
    parentLayer.addSublayer(videoLayer)
    parentLayer.addSublayer(effectLayer)
    parentLayer.display()
    videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
      postProcessingAsVideoLayers: [videoLayer],
      in: parentLayer
    )
    exportSession.videoComposition = videoComposition
  }
  exportSession.timeRange = effects.timeRange ?? CMTimeRange(start: .zero, duration: .positiveInfinity)
  try? FileManager.default.removeItem(at: config.outputURL)
  exportSession.exportAsynchronously {
    if exportSession.status != AVAssetExportSession.Status.completed {
      return resultHandler(.failure(.exportFailed))
    }
    resultHandler(.success(config.outputURL))
  }
}
