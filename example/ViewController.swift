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
    guard let exportSession = AVAssetExportSession(
      asset: asset, presetName: AVAssetExportPresetHighestQuality
    ) else {
      return
    }
    applyEffects(exportSession: exportSession, effects: [
      TrimEffect(range: CMTimeRange(start: .zero, end: CMTime(seconds: 1, preferredTimescale: 600))),
    ])
    exportSession.outputFileType = .mov
    exportSession.outputURL = try? makeTemporaryFile(for: .mov)
    exportSession.exportAsynchronously {
      if exportSession.status != AVAssetExportSession.Status.completed {
        fatalError("Failed to export")
      }
      print("Completed successfully")
      print(exportSession.outputURL as Any)
    }
  }
}
