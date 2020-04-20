import AVFoundation
import MobileCoreServices

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
    
    // TODO: repeat for all video tracks
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
    
    let videoTrackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.layerInstructions = [
      videoTrackInstruction
    ]
    instruction.enablePostProcessing = true
    instruction.timeRange = videoTrack.timeRange
    composition.instructions = [instruction]
    exportSession.videoComposition = composition
  }
}

public func applyEffects(exportSession: AVAssetExportSession, effects: [Effect]) {
  effects.forEach { $0.apply(exportSession: exportSession) }
}

// File utils

public func makeRandomFileName() -> String {
  let random_int = arc4random_uniform(.max)
  return NSString(format: "%x", random_int) as String
}

public func fileExtension(for fileType: AVFileType) -> String? {
  if let ext = UTTypeCopyPreferredTagWithClass(fileType as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue() {
    return ext as String
  }
  return .none
}

public func makeTemporaryFile(for fileType: AVFileType, fileName: String = makeRandomFileName()) throws -> URL {
  let outputTemporaryDirectoryURL = try FileManager.default
    .url(
      for: .itemReplacementDirectory,
      in: .userDomainMask,
      appropriateFor: FileManager.default.temporaryDirectory,
      create: true
    )
  let outputURL = outputTemporaryDirectoryURL
    .appendingPathComponent(fileName)
    .appendingPathExtension(fileExtension(for: fileType) ?? "")
  try? FileManager.default.removeItem(at: outputURL)
  return outputURL
}
