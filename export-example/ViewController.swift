import VideoEffects
import AVFoundation
import UIKit

class ViewController: UIViewController {

  let exportButton = UIButton()
  
  @objc
  private func onExportButtonPress() {
    guard let exampleVideoURL = Bundle.main.url(forResource: "example-depth", withExtension: "mov") else {
      fatalError("Failed to find example video file")
    }
    let asset = AVAsset(url: exampleVideoURL)
    let effects = createEffectsForDemo()
    
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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    exportButton.setTitle("Export", for: .normal)
    exportButton.contentEdgeInsets  = UIEdgeInsets(top: 5, left: 20, bottom: 5, right: 20)
    exportButton.sizeToFit()
    exportButton.backgroundColor = .red
    exportButton.translatesAutoresizingMaskIntoConstraints = false
    exportButton.addTarget(self, action: #selector(onExportButtonPress), for: .touchUpInside)
    view.addSubview(exportButton)
    view.addConstraint(
      NSLayoutConstraint(
        item: exportButton,
        attribute: .centerX,
        relatedBy: .equal,
        toItem: view,
        attribute: .centerX,
        multiplier: 1,
        constant: 0
      )
    )
    view.addConstraint(
      NSLayoutConstraint(
        item: exportButton,
        attribute: .centerY,
        relatedBy: .equal,
        toItem: view,
        attribute: .centerY,
        multiplier: 1,
        constant: 0
      )
    )
  }
}

