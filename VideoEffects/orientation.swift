import AVFoundation

enum Orientation {
  case up, down, right, left
}

private func transformOrientation(_ t: CGAffineTransform) -> Orientation {
  if t.a == 0, t.b == 1.0, t.c == -1.0, t.d == 0 {
    return .up
  } else if t.a == 0, t.b == -1.0, t.c == 1.0, t.d == 0 {
    return .down
  } else if t.a == 1.0, t.b == 0, t.c == 0, t.d == 1.0 {
    return .right
  } else if t.a == -1.0, t.b == 0, t.c == 0, t.d == -1.0 {
    return .left
  } else {
    return .up
  }
}

func orientationTransform(forVideoTrack videoTrack: AVAssetTrack) -> CGAffineTransform {
  let preferredTransform = videoTrack.preferredTransform
  let angleRadians = CGFloat(atan2f(Float(preferredTransform.b), Float(preferredTransform.a)))
  let naturalSize = videoTrack.naturalSize
  let transformedSize = naturalSize.applying(videoTrack.preferredTransform.inverted())
  let orientation = transformOrientation(preferredTransform)
  if orientation == .up {
    return CGAffineTransform.identity
      .rotated(by: -angleRadians)
      .translatedBy(x: transformedSize.height, y: 0)
  }
  if orientation == .down {
    return CGAffineTransform.identity
      .rotated(by: -angleRadians)
      .translatedBy(x: 0, y: transformedSize.width)
  }
  if orientation == .left {
    return CGAffineTransform.identity
      .scaledBy(x: 1, y: -1)
      .translatedBy(x: 0, y: transformedSize.height)
  }
  return .identity
}
