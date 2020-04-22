import AVFoundation

public protocol VideoWriterInput {
  associatedtype InputType
  var input: AVAssetWriterInput { get }
  var isEnabled: Bool { get set }
  func append(_: InputType)
  func finish()
}
