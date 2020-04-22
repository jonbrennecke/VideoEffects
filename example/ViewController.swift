import AVFoundation
import UIKit
import VideoEffects

class ViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    guard let exampleVideoURL = Bundle.main.url(forResource: "example", withExtension: "mov") else {
      fatalError("Failed to find example video file")
    }
    let asset = AVAsset(url: exampleVideoURL)
    exportAsset(asset: asset)
  }

  func exportAsset(asset: AVAsset) {
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
    textLayer.display() // Calling "display()" is necessary for CATextLayers due to an open radar: http://www.openradar.me/32718905
    layer.backgroundColor = UIColor.purple.cgColor
    layer.frame = textLayer.frame
    layer.addSublayer(textLayer)
    layer.masksToBounds = true

    let effects: [Effect] = [
      TrimEffect(range: CMTimeRange(start: .zero, end: CMTime(seconds: 3, preferredTimescale: 600))),
      CropEffect(aspectRatio: CGSize(width: 1, height: 1)),
      ColorControlsEffect(brightness: 0, saturation: 0, contrast: 1),
      LayerEffect(layer: layer),
//      AudioEffect()
    ]
    guard let exportConfig = try? ExportConfig.defaultConfig() else {
      fatalError("Failed to configure export.")
    }
    export(asset: asset, effects: effects, config: exportConfig) { result in
      switch result {
      case let .success(url):
        print(url)
      case let .failure(error):
        print(error)
      }
    }
  }
}
