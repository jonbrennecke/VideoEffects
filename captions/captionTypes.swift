import UIKit

public struct CaptionStyle {
  let wordStyle: CaptionWordStyle
  let lineStyle: CaptionLineStyle
  let textAlignment: CaptionTextAlignment
  let backgroundStyle: CaptionBackgroundStyle
  let backgroundColor: UIColor
  let font: UIFont
  let textColor: UIColor
  let textShadow: TextShadow
  
  public class TextShadow {
    let opacity: Float
    let color: UIColor
    
    public init(opacity: Float, color: UIColor) {
      self.opacity = opacity
      self.color = color
    }
  }

  public init(
    wordStyle: CaptionWordStyle,
    lineStyle: CaptionLineStyle,
    textAlignment: CaptionTextAlignment,
    backgroundStyle: CaptionBackgroundStyle,
    backgroundColor: UIColor,
    font: UIFont,
    textColor: UIColor,
    textShadow: TextShadow
  ) {
    self.wordStyle = wordStyle
    self.lineStyle = lineStyle
    self.textAlignment = textAlignment
    self.backgroundStyle = backgroundStyle
    self.backgroundColor = backgroundColor
    self.font = font
    self.textColor = textColor
    self.textShadow = textShadow
  }
}

public enum CaptionWordStyle {
  case animated
  case none
}

public enum CaptionLineStyle {
  case fadeInOut(numberOfLines: Int, padding: Padding)
  case translateUp

  public struct Padding {
    let vertical: Float

    public init(vertical: Float) {
      self.vertical = vertical
    }
  }
}

public enum CaptionTextAlignment {
  case center
  case left
  case right

  public func textLayerAlignmentMode() -> CATextLayerAlignmentMode {
    switch self {
    case .center:
      return .center
    case .left:
      return .left
    case .right:
      return .right
    }
  }
}

public enum CaptionBackgroundStyle {
  case none
  case solid
  case gradient
  case textBoundingBox
}

public struct CaptionTextSegment {
  let duration: CFTimeInterval
  let timestamp: CFTimeInterval
  let text: String

  public init(duration: CFTimeInterval, timestamp: CFTimeInterval, text: String) {
    self.duration = duration
    self.timestamp = timestamp
    self.text = text
  }
}
