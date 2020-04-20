import AVFoundation
import MobileCoreServices

public protocol Effect {
  func apply(exportSession: AVAssetExportSession)
}

public struct TrimEffect {
  let range: CMTimeRange

  public init(range: CMTimeRange) {
    self.range = range
  }
}

extension TrimEffect: Effect {
  public func apply(exportSession: AVAssetExportSession) {
    exportSession.timeRange = range
  }
}

public func applyEffects(exportSession: AVAssetExportSession, effects: [Effect]) {
  effects.forEach { $0.apply(exportSession: exportSession) }
}

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
