import AVFoundation
import UIKit

func effectRenderSize(aspectRatio: CGSize, naturalSize: CGSize) -> CGSize {
  // dimensions are reversed if video is in portrait orientation
  // videoTrack.naturalSize.applying(videoTrack.preferredTransform)
  // CGSize(width: abs(size.width), height: abs(size.height))
  let ratio = aspectRatio.width / aspectRatio.height
  let height = naturalSize.height
  let width = height * ratio
  return CGSize(width: width, height: height)
}

public protocol EffectPlayerViewPlaybackDelegate {
  func effectPlayer(view: EffectPlayerView, didUpdateProgress progress: CFTimeInterval)
  func effectPlayer(view: EffectPlayerView, didChangePlaybackState playbackState: EffectPlayerView.PlaybackState)
  func effectPlayerDidPlayToEnd(_ view: EffectPlayerView)
}

open class EffectPlayerView: UIView {
  public enum PlaybackState: Int {
    case paused
    case playing
    case waiting
    case readyToPlay
  }

  private let playerLayer = AVPlayerLayer()

  private lazy var player: AVPlayer = {
    let player = AVPlayer()
    player.volume = 1
    return player
  }()

  private var playerItem: AVPlayerItem?

  private var playbackTimeObserverToken: Any?

  // MARK: public vars

  public var playbackDelegate: EffectPlayerViewPlaybackDelegate?

  public var effects: EffectConfig = EffectConfig() {
    didSet {
      configurePlayer()
    }
  }

  public var asset: AVAsset? {
    didSet {
      configurePlayer()
    }
  }

  // MARK: public methods

  public func play() {
    player.play()
  }

  public func pause() {
    player.pause()
  }

  public func seek(to time: CMTime) {
    player.seek(to: time)
  }

  public func seek(to progress: Double) {
    if let duration = player.currentItem?.duration {
      let durationSeconds = CMTimeGetSeconds(duration)
      let time = CMTimeMakeWithSeconds(durationSeconds * progress, preferredTimescale: 600)
      seek(to: time)
    }
  }

  // MARK: UIView methods

  public override func didMoveToSuperview() {
    super.didMoveToSuperview()
    layer.addSublayer(playerLayer)
    if let effectLayer = effects.layer {
      playerLayer.addSublayer(effectLayer)
    }
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    playerLayer.backgroundColor = UIColor.black.cgColor
    playerLayer.frame = bounds
    if let effectLayer = effects.layer {
      let renderSize = playerItem?.videoComposition?.renderSize ?? .zero
      effectLayer.frame = AVMakeRect(aspectRatio: effects.aspectRatio ?? renderSize, insideRect: frame)
    }
  }

  // MARK: private methods

  private func createVideoComposition(withAsset asset: AVAsset) -> (AVComposition, AVVideoComposition) {
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

  private func createPlayerItem() -> AVPlayerItem? {
    if let asset = asset {
      let (composition, videoComposition) = createVideoComposition(withAsset: asset)
      let playerItem = AVPlayerItem(asset: composition)
      playerItem.videoComposition = videoComposition
      if let compositor = playerItem.customVideoCompositor as? Compositor {
        compositor.filters = effects.filters
        if let videoTrack = asset.tracks(withMediaType: .video).first {
          compositor.transform = orientationTransform(forVideoTrack: videoTrack)
        }
      }
      return playerItem
    }
    return nil
  }

  private func configurePlayer() {
    let audioSession = AVAudioSession.sharedInstance()
    try? audioSession.setCategory(.playback)
    try? audioSession.setActive(true, options: .init())
    playerItem = createPlayerItem()
    playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.error), options: [.old, .new], context: nil)
    player.replaceCurrentItem(with: playerItem)
    if let timeRange = effects.timeRange {
      playerItem?.reversePlaybackEndTime = timeRange.start
      playerItem?.forwardPlaybackEndTime = timeRange.end
    }
    player.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: [.old, .new], context: nil)
    player.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [.old, .new], context: nil)
    player.addObserver(self, forKeyPath: #keyPath(AVPlayer.error), options: [.old, .new], context: nil)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onDidPlayToEndNotification),
      name: Notification.Name.AVPlayerItemDidPlayToEndTime,
      object: nil
    )
    playerLayer.player = player
  }

  @objc
  private func onDidPlayToEndNotification() {
    playbackDelegate?.effectPlayerDidPlayToEnd(self)
  }

  public override func observeValue(
    forKeyPath keyPath: String?, of _: Any?, change: [NSKeyValueChangeKey: Any]?, context _: UnsafeMutableRawPointer?
  ) {
    if
      keyPath == #keyPath(AVPlayer.status),
      let statusRawValue = change?[.newKey] as? NSNumber,
      let status = AVPlayer.Status(rawValue: statusRawValue.intValue) {
      if case .readyToPlay = status {
        onReadyToPlay()
      }
    }
    
    if keyPath == #keyPath(AVPlayer.error) {
      // TODO: handle error with a delegate method
    }
    
    if keyPath == #keyPath(AVPlayerItem.error) {
      // TODO: handle error with a delegate method
    }

    if
      keyPath == #keyPath(AVPlayer.timeControlStatus),
      let newStatusRawValue = change?[.newKey] as? NSNumber,
      let oldStatusRawValue = change?[.oldKey] as? NSNumber,
      oldStatusRawValue != newStatusRawValue,
      let status = AVPlayer.TimeControlStatus(rawValue: newStatusRawValue.intValue) {
      switch status {
      case .waitingToPlayAtSpecifiedRate:
        playbackDelegate?.effectPlayer(view: self, didChangePlaybackState: .waiting)
      case .paused:
        playbackDelegate?.effectPlayer(view: self, didChangePlaybackState: .paused)
      case .playing:
        playbackDelegate?.effectPlayer(view: self, didChangePlaybackState: .playing)
      @unknown default:
        break
      }
    }
  }

  private func addPeriodicTimeObserver() {
    let timeScale = CMTimeScale(NSEC_PER_SEC)
    let timeInterval = CMTime(seconds: 1 / 30, preferredTimescale: timeScale)
    playbackTimeObserverToken = player.addPeriodicTimeObserver(
      forInterval: timeInterval,
      queue: .main,
      using: { [weak self] playbackTime in
        guard let strongSelf = self, let duration = strongSelf.playerItem?.duration else { return }
        let playbackTimeSeconds = CMTimeGetSeconds(playbackTime)
        let durationSeconds = CMTimeGetSeconds(duration)
        let progress = clamp(playbackTimeSeconds / durationSeconds, min: Float64(0), max: durationSeconds)
        strongSelf.playbackDelegate?.effectPlayer(view: strongSelf, didUpdateProgress: progress)
      }
    )
  }

  private func removePeriodicTimeObserver() {
    if let token = playbackTimeObserverToken {
      player.removeTimeObserver(token)
      playbackTimeObserverToken = nil
    }
  }

  private func onReadyToPlay() {
    removePeriodicTimeObserver()
    addPeriodicTimeObserver()
    player.play()
    playbackDelegate?.effectPlayer(view: self, didChangePlaybackState: .readyToPlay)
  }
}
