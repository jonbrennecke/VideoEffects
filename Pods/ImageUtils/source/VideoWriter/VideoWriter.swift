import AVFoundation

public class VideoWriter {
  internal static let queue = DispatchQueue(label: "com.jonbrennecke.HSVideoWriter.inputQueue")

  private enum State {
    case notReady
    case readyToRecord(assetWriter: AVAssetWriter)
    case recording(assetWriter: AVAssetWriter, startTime: CMTime)
  }

  public enum HSVideoWriterResult {
    case success
    case failure
  }

  private var state: State

  public init() {
    state = .notReady
  }

  public func prepareToRecord(to url: URL, fileType: AVFileType = .mov) -> HSVideoWriterResult {
    guard let assetWriter = try? AVAssetWriter(outputURL: url, fileType: fileType) else {
      return .failure
    }
    state = .readyToRecord(assetWriter: assetWriter)
    return .success
  }

  public func add<T: VideoWriterInput>(input: T) -> HSVideoWriterResult {
    guard case let .readyToRecord(assetWriter) = state else {
      return .failure
    }
    if assetWriter.canAdd(input.input) {
      assetWriter.add(input.input)
      return .success
    }
    return .failure
  }

  public func add(metadataItem: AVMetadataItem) -> HSVideoWriterResult {
    guard case let .readyToRecord(assetWriter) = state else {
      return .failure
    }
    assetWriter.metadata.append(metadataItem)
    return .success
  }

  public func startRecording(at startTime: CMTime) -> HSVideoWriterResult {
    guard case let .readyToRecord(assetWriter) = state else {
      return .failure
    }
    state = .recording(assetWriter: assetWriter, startTime: startTime)
    if !assetWriter.startWriting() {
      return .failure
    }
    assetWriter.startSession(atSourceTime: startTime)
    return .success
  }

  public func stopRecording(at endTime: CMTime, _ completionHandler: @escaping (URL) -> Void) {
    guard case let .recording(assetWriter, _) = state else {
      return
    }
    assetWriter.endSession(atSourceTime: endTime)
    assetWriter.finishWriting {
      completionHandler(assetWriter.outputURL)
    }
  }
}
