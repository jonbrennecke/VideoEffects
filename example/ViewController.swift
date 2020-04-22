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
    let effects: [Effect] = [
      TrimEffect(range: CMTimeRange(start: .zero, end: CMTime(seconds: 1, preferredTimescale: 600))),
      CropEffect(aspectRatio: CGSize(width: 1, height: 1)),
      ColorControlsEffect(brightness: 0, saturation: 0, contrast: 1),
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
