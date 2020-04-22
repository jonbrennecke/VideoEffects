import AVFoundation

public class VideoWriterMetadataInput: VideoWriterInput {
  public typealias InputType = AVMetadataItem

  private let metadataInput: AVAssetWriterInput

  public var isEnabled: Bool = true {
    didSet {
      metadataInput.marksOutputTrackAsEnabled = isEnabled
    }
  }

  public var input: AVAssetWriterInput {
    return metadataInput
  }

  public init(isRealTime: Bool = false) {
    metadataInput = AVAssetWriterInput(mediaType: .metadata, outputSettings: nil)
    metadataInput.expectsMediaDataInRealTime = isRealTime
  }

  public func append(_ metadataItem: AVMetadataItem) {
    if input.isReadyForMoreMediaData {
      metadataInput.metadata.append(metadataItem)
    }
  }

  public func finish() {
    metadataInput.markAsFinished()
  }
}
