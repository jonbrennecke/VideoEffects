import AVFoundation
import MobileCoreServices

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

public func createTemporaryUrl(for fileType: AVFileType, fileName: String = makeRandomFileName()) throws -> URL {
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
  return outputURL
}
