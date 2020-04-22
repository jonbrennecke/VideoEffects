import AVFoundation

public class VideoWriterTimedMetadataInput: VideoWriterInput {
  public typealias InputType = AVTimedMetadataGroup

  private let metadataInput: AVAssetWriterInput
  private let metadataAdaptor: AVAssetWriterInputMetadataAdaptor

  public var isEnabled: Bool = true {
    didSet {
      metadataInput.marksOutputTrackAsEnabled = isEnabled
    }
  }

  public var input: AVAssetWriterInput {
    return metadataInput
  }

  @available(macOS, unavailable)
  public init(isRealTime: Bool = true) {
    metadataInput = AVAssetWriterInput(mediaType: .metadataObject, outputSettings: nil)
    metadataInput.expectsMediaDataInRealTime = isRealTime
    metadataAdaptor = AVAssetWriterInputMetadataAdaptor(assetWriterInput: metadataInput)
  }

  public func append(_ timedMetadataGroup: AVTimedMetadataGroup) {
    if input.isReadyForMoreMediaData {
      metadataAdaptor.append(timedMetadataGroup)
    }
  }

  public func finish() {
    metadataInput.markAsFinished()
  }
}
