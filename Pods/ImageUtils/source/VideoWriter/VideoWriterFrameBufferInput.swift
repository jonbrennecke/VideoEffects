import AVFoundation

public class VideoWriterFrameBufferInput: VideoWriterInput {
  public typealias InputType = VideoFrameBuffer

  private let videoInput: AVAssetWriterInput
  private let pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor

  public var isEnabled: Bool = true {
    didSet {
      videoInput.marksOutputTrackAsEnabled = isEnabled
    }
  }

  public var input: AVAssetWriterInput {
    return videoInput
  }

  public init(videoSize: Size<Int>, pixelFormatType: OSType, isRealTime: Bool = true) {
    let videoSettings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: videoSize.width as NSNumber,
      AVVideoHeightKey: videoSize.height as NSNumber,
    ]
    videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
    videoInput.expectsMediaDataInRealTime = isRealTime
    pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
      assetWriterInput: videoInput,
      sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey: pixelFormatType,
        kCVPixelBufferWidthKey: videoSize.width,
        kCVPixelBufferHeightKey: videoSize.height,
      ] as [String: Any]
    )
  }

  public func append(_ videoFrameBuffer: VideoFrameBuffer) {
    if input.isReadyForMoreMediaData {
      let buffer = videoFrameBuffer.pixelBuffer.buffer
      pixelBufferAdaptor.append(buffer, withPresentationTime: videoFrameBuffer.presentationTime)
    }
  }

  public func finish() {
    videoInput.markAsFinished()
  }
}
