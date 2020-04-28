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
  func videoComposition(view: EffectPlayerView, didUpdateProgress progress: CFTimeInterval)
  func videoComposition(view: EffectPlayerView, didChangePlaybackState playbackState: EffectPlayerView.PlaybackState)
  func videoCompositionDidPlayToEnd(_ view: EffectPlayerView)
}

public class EffectPlayerView: UIView {
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

  private func createVideoComposition(videoTrack: AVAssetTrack) -> AVVideoComposition? {
    guard videoTrack.mediaType == .video else {
      return nil
    }
    let composition = AVMutableVideoComposition()
    composition.customVideoCompositorClass = Compositor.self
    let videoTrackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
    let instruction = AVMutableVideoCompositionInstruction()
    instruction.layerInstructions = [
      videoTrackInstruction,
    ]
    instruction.enablePostProcessing = true
    instruction.timeRange = videoTrack.timeRange
    composition.renderSize = effects.aspectRatio != nil
      ? effectRenderSize(aspectRatio: effects.aspectRatio!, naturalSize: videoTrack.naturalSize)
      : videoTrack.naturalSize
    composition.frameDuration = CMTimeMake(value: 1, timescale: CMTimeScale(videoTrack.nominalFrameRate))
    composition.instructions = [instruction]
    return composition
  }

  private func createPlayerItem() -> AVPlayerItem? {
    if let asset = asset, let videoTrack = asset.tracks(withMediaType: .video).first {
      let playerItem = AVPlayerItem(asset: asset)
      playerItem.videoComposition = createVideoComposition(videoTrack: videoTrack)
      if let compositor = playerItem.customVideoCompositor as? Compositor {
        compositor.filter = ColorControlsCompositorFilter(
          videoTrack: videoTrack.trackID,
          brightness: effects.colorControls.brightness,
          saturation: effects.colorControls.saturation,
          contrast: effects.colorControls.contrast
        )
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
    player.replaceCurrentItem(with: playerItem)
    if let timeRange = effects.timeRange {
      playerItem?.reversePlaybackEndTime = timeRange.start
      playerItem?.forwardPlaybackEndTime = timeRange.end
    }
    player.addObserver(self, forKeyPath: #keyPath(AVPlayer.status), options: [.old, .new], context: nil)
    player.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [.old, .new], context: nil)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(onDidPlayToEndNotification),
      name: Notification.Name.AVPlayerItemDidPlayToEndTime,
      object: nil
    )
    playerLayer.player = player
  }

  @objc
  private func onDidPlayToEndNotification() {}

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

    if
      keyPath == #keyPath(AVPlayer.timeControlStatus),
      let newStatusRawValue = change?[.newKey] as? NSNumber,
      let oldStatusRawValue = change?[.oldKey] as? NSNumber,
      oldStatusRawValue != newStatusRawValue,
      let status = AVPlayer.TimeControlStatus(rawValue: newStatusRawValue.intValue) {
      switch status {
      case .waitingToPlayAtSpecifiedRate:
        playbackDelegate?.videoComposition(view: self, didChangePlaybackState: .waiting)
      case .paused:
        playbackDelegate?.videoComposition(view: self, didChangePlaybackState: .paused)
      case .playing:
        playbackDelegate?.videoComposition(view: self, didChangePlaybackState: .playing)
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
        strongSelf.playbackDelegate?.videoComposition(view: strongSelf, didUpdateProgress: progress)
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
    playbackDelegate?.videoComposition(view: self, didChangePlaybackState: .readyToPlay)
  }
}
