import AVFoundation

func makeWordStyleLayer(
  within bounds: CGRect,
  stringSegments: [CaptionStringSegment],
  style: CaptionStyle,
  duration: CFTimeInterval
) -> CALayer {
  switch style.wordStyle {
  case .animated:
    return makeAnimatedWordStyleLayer(
      within: bounds,
      segments: stringSegments,
      style: style,
      duration: duration
    )
  default:
    return makeDefaultTextStyleLayer(
      within: bounds,
      style: style,
      stringSegments: stringSegments
    )
  }
}
