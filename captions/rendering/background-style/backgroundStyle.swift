import AVFoundation

func renderBackgroundStyle(
  captionStyle: CaptionStyle,
  layer: CALayer,
  backgroundHeight: Float,
  map: CaptionStringsMap,
  getSizeOfRow: @escaping (CaptionRowKey) -> CGSize
) {
  switch captionStyle.backgroundStyle {
  case .gradient:
    return renderGradientBackgroundStyle(
      captionStyle: captionStyle,
      layer: layer,
      backgroundHeight: backgroundHeight
    )
  case .solid:
    return renderSolidBackgroundStyle(
      captionStyle: captionStyle,
      layer: layer,
      map: map
    )
  case .textBoundingBox:
    return renderTextBoundingBoxBackgroundStyle(
      captionStyle: captionStyle,
      layer: layer,
      map: map,
      getSizeOfRow: getSizeOfRow
    )
  }
}

func renderSolidBackgroundStyle(
  captionStyle: CaptionStyle,
  layer: CALayer,
  map: CaptionStringsMap
) {
  guard
    let rowSegments = map.segmentsByRow[.a],
    let beginTime = rowSegments.first?.first?.timestamp
  else {
    return
  }
  let backgroundLayer = CALayer()
  backgroundLayer.frame = layer.bounds
  backgroundLayer.opacity = 0
  backgroundLayer.backgroundColor = captionStyle.backgroundColor.withAlphaComponent(0.9).cgColor
  backgroundLayer.masksToBounds = true
  layer.insertSublayer(backgroundLayer, at: 0)
  let animation = AnimationUtil.fadeIn(at: beginTime - 0.25)
  backgroundLayer.add(animation, forKey: nil)
}

import UIKit

func renderGradientBackgroundStyle(
  captionStyle: CaptionStyle,
  layer: CALayer,
  backgroundHeight: Float
) {
  let beginTime = CFTimeInterval(0)
  let backgroundLayer = CALayer()
  backgroundLayer.frame = layer.bounds
  backgroundLayer.masksToBounds = false
  let gradientLayer = createGradientLayer(color: captionStyle.backgroundColor)
  gradientLayer.frame = CGRect(
    origin: .zero,
    size: CGSize(width: layer.bounds.width, height: CGFloat(backgroundHeight))
  )
  backgroundLayer.insertSublayer(gradientLayer, at: 0)
  layer.insertSublayer(backgroundLayer, at: 0)
  let animation = AnimationUtil.fadeIn(at: beginTime)
  backgroundLayer.add(animation, forKey: nil)
}

fileprivate func createGradientLayer(color: UIColor) -> CAGradientLayer {
  let gradientLayer = CAGradientLayer()
  gradientLayer.colors = [
    color.withAlphaComponent(0.8).cgColor,
    color.withAlphaComponent(0).cgColor,
  ]
  gradientLayer.locations = [0, 1]
  gradientLayer.startPoint = CGPoint(x: 0.5, y: 1)
  gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
  return gradientLayer
}

fileprivate struct Padding {
  let vertical: Float
  let horizontal: Float
}

fileprivate let padding = Padding(vertical: 0.75, horizontal: 0.75)

func renderTextBoundingBoxBackgroundStyle(
  captionStyle: CaptionStyle,
  layer: CALayer,
  map: CaptionStringsMap,
  getSizeOfRow: @escaping (CaptionRowKey) -> CGSize
) {
  let attributes = stringAttributes(for: captionStyle)
  let backgroundLayer = CALayer()
  backgroundLayer.backgroundColor = captionStyle.backgroundColor.cgColor
  let rowBoundingRects = map.segmentsByRow.flatMap({ key, rowSegments -> [CGRect] in
    let rowSize = getSizeOfRow(key)
    return rowSegments.map {
      let str = string(from: $0)
      let attributedString = NSAttributedString(string: str, attributes: attributes)
      return attributedString.boundingRect(with: rowSize, options: [], context: nil)
    }
  })
  let rowSize = getSizeOfRow(.a)
  let attributedString = NSAttributedString(string: "—", attributes: attributes)
  let emSize = attributedString.boundingRect(with: rowSize, options: [], context: nil).size
  guard
    let widestRect = rowBoundingRects.max(by: { $0.width < $1.width }),
    let tallestRect = rowBoundingRects.max(by: { $0.height < $1.height })
  else {
    return
  }
  let horizontalPadding = CGFloat(padding.horizontal) * emSize.width
  let verticalPadding = CGFloat(padding.vertical) * emSize.height
  let size = CGSize(
    width: widestRect.width + horizontalPadding,
    height: tallestRect.height * 2 + verticalPadding
  )
  let origin = CGPoint(
    x: abs(layer.frame.width - size.width) / 2,
    y: abs(layer.frame.height - size.height) / 2
  )
  let frame = CGRect(origin: origin, size: size)
  backgroundLayer.cornerRadius = 5
  backgroundLayer.frame = frame
  backgroundLayer.masksToBounds = false
  layer.insertSublayer(backgroundLayer, at: 0)
}
