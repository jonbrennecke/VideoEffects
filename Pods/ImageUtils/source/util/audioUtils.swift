import AVFoundation

public enum CreateDownsampledAudioAssetError: Error {
  case assetMissingAudioTrack
  case failedToCreateOutputFile
  case failedToReadAsset
  case failedToSetupAssetWriter
  case failedWithError(Error)
}

fileprivate let downsampleQueue = DispatchQueue(label: "downsampleQueue", qos: .background)

public func createDownSampledAudio(
  asset: AVAsset,
  completionHandler: @escaping (Result<URL, CreateDownsampledAudioAssetError>) -> Void
) {
  var channelLayout = AudioChannelLayout()
  channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Mono
  channelLayout.mChannelBitmap = AudioChannelBitmap(rawValue: 0)
  channelLayout.mNumberChannelDescriptions = 0
  let channelLayoutAsData = Data(bytes: &channelLayout, count: MemoryLayout.size(ofValue: channelLayout))
  let compressionAudioSettings: [String: Any] = [
    AVNumberOfChannelsKey: 1,
    AVSampleRateKey: 16000,
    AVFormatIDKey: kAudioFormatMPEG4AAC,
    AVChannelLayoutKey: channelLayoutAsData,
  ]
  let decompressionAudioSettings: [String: Any] = [
    AVFormatIDKey: kAudioFormatLinearPCM,
  ]
  do {
    guard let outputURL = try? makeEmptyTemporaryFile(withPathExtension: "m4a") else {
      return completionHandler(.failure(.failedToCreateOutputFile))
    }
    let assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .m4a)
    let assetReader = try AVAssetReader(asset: asset)

    // input
    let assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: compressionAudioSettings)
    assetWriterAudioInput.expectsMediaDataInRealTime = false
    guard assetWriter.canAdd(assetWriterAudioInput) else {
      return completionHandler(.failure(.failedToSetupAssetWriter))
    }
    assetWriter.add(assetWriterAudioInput)

    // output
    guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
      return completionHandler(.failure(.assetMissingAudioTrack))
    }
    let assetReaderTrackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: decompressionAudioSettings)
    assetReaderTrackOutput.alwaysCopiesSampleData = true
    guard assetReader.canAdd(assetReaderTrackOutput) else {
      return completionHandler(.failure(.failedToReadAsset))
    }
    assetReader.add(assetReaderTrackOutput)

    assetReader.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
    assetReader.startReading()
    assetWriter.startWriting()
    assetWriter.startSession(atSourceTime: .zero)
    assetWriterAudioInput.requestMediaDataWhenReady(on: downsampleQueue) {
      while assetReader.status == .reading {
        if assetWriterAudioInput.isReadyForMoreMediaData {
          if let sampleBuffer = assetReaderTrackOutput.copyNextSampleBuffer(), CMSampleBufferDataIsReady(sampleBuffer) {
            assetWriterAudioInput.append(sampleBuffer)
          } else {
            assetWriterAudioInput.markAsFinished()
          }
        }
        if assetReader.status == .failed, let error = assetReader.error {
          assetReader.cancelReading()
          assetWriter.cancelWriting()
          return completionHandler(.failure(.failedWithError(error)))
        }
      }
      assetWriter.finishWriting {
        completionHandler(.success(outputURL))
      }
    }
  } catch {
    return completionHandler(.failure(.failedWithError(error)))
  }
}

public enum CreateAudioFileError: Error {
  case failedToCreateExportSession
  case assetMissingAudioTrack
  case failedToExportAudioFile
}

public func createTemporaryAudioFile(
  fromAsset asset: AVAsset,
  completionHandler: @escaping (Result<URL, CreateAudioFileError>) -> Void
) {
  let audioAssetTracks = asset.tracks(withMediaType: .audio)
  guard let audioAssetTrack = audioAssetTracks.last else {
    return completionHandler(.failure(.assetMissingAudioTrack))
  }
  guard
    let outputURL = try? makeEmptyTemporaryFile(withPathExtension: "m4a"),
    let assetExportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
  else {
    return completionHandler(.failure(.failedToCreateExportSession))
  }
  assetExportSession.outputURL = outputURL
  assetExportSession.outputFileType = .m4a
  assetExportSession.timeRange = audioAssetTrack.timeRange
  assetExportSession.exportAsynchronously {
    if assetExportSession.status == .failed {
      return completionHandler(.failure(.failedToExportAudioFile))
    }
    completionHandler(.success(outputURL))
  }
}

fileprivate func makeEmptyTemporaryFile(withPathExtension pathExtension: String) throws -> URL {
  let outputTemporaryDirectoryURL = try FileManager.default
    .url(
      for: .itemReplacementDirectory,
      in: .userDomainMask,
      appropriateFor: FileManager.default.temporaryDirectory,
      create: true
    )
  let outputURL = outputTemporaryDirectoryURL
    .appendingPathComponent(makeRandomFileName())
    .appendingPathExtension(pathExtension)
  try? FileManager.default.removeItem(at: outputURL)
  return outputURL
}

fileprivate func makeRandomFileName() -> String {
  let random_int = arc4random_uniform(.max)
  return NSString(format: "%x", random_int) as String
}
