import AVFoundation
import UIKit
import VideoEffects

class ViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    guard let exampleVideoURL = Bundle.main.url(forResource: "example-depth", withExtension: "mov") else {
      fatalError("Failed to find example video file")
    }
    let effectView = EffectPlayerView()
    effectView.effects = c
    effectView.asset = AVAsset(url: exampleVideoURL)
    effectView.frame = view.frame
    view.addSubview(effectView)
  }

  func createEffectsForDemo() -> EffectConfig {
    let layer = CALayer()
    let textLayer = CATextLayer()
    let string = NSAttributedString(string: "Hello World", attributes: [
      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 25),
      NSAttributedString.Key.foregroundColor: UIColor.white.cgColor,
      NSAttributedString.Key.backgroundColor: UIColor.blue.cgColor,
    ])
    textLayer.string = string
    textLayer.frame = CGRect(origin: .zero, size: string.size())
    textLayer.backgroundColor = UIColor.red.cgColor
    textLayer.foregroundColor = UIColor.white.cgColor
    textLayer
      .display() // Calling "display()" is necessary for CATextLayers due to an open radar: http://www.openradar.me/32718905
    layer.frame = textLayer.frame
    layer.addSublayer(textLayer)
    layer.masksToBounds = true
    return EffectConfig(
      filters: [
        ColorControlsFilter.grayscale,
      ],
      aspectRatio: nil,
      timeRange: CMTimeRange(start: .zero, end: CMTime(seconds: 3, preferredTimescale: 600)),
      layer: layer
    )
  }
}
