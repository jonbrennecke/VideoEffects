import AVFoundation

public class VideoWriterAudioInput: VideoWriterInput {
  public typealias InputType = CMSampleBuffer

  private let audioInput: AVAssetWriterInput

  public static let defaultOutputSettings: [String: Any] = [
    AVNumberOfChannelsKey: 1,
    AVSampleRateKey: 44100,
    AVEncoderAudioQualityForVBRKey: 91,
    AVEncoderBitRateStrategyKey: AVAudioBitRateStrategy_Variable,
    AVFormatIDKey: kAudioFormatMPEG4AAC,
    AVEncoderBitRatePerChannelKey: 96000,
  ]

  public var isEnabled: Bool = true {
    didSet {
      audioInput.marksOutputTrackAsEnabled = isEnabled
    }
  }

  public var input: AVAssetWriterInput {
    return audioInput
  }

  public init(isRealTime: Bool = true, outputSettings: [String: Any] = VideoWriterAudioInput.defaultOutputSettings) {
    audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: outputSettings)
    audioInput.expectsMediaDataInRealTime = isRealTime
  }

  public func append(_ sampleBuffer: CMSampleBuffer) {
    if input.isReadyForMoreMediaData {
      input.append(sampleBuffer)
    }
  }

  public func finish() {
    input.markAsFinished()
  }
}
