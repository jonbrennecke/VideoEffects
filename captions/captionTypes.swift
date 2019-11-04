import UIKit

public struct CaptionStyle {
  let wordStyle: CaptionWordStyle
  let lineStyle: CaptionLineStyle
  let backgroundStyle: CaptionBackgroundStyle
  let backgroundColor: UIColor
  let textStyle: TextStyle

  public struct TextStyle {
    let font: UIFont
    let color: UIColor
    let shadow: Shadow
    let alignment: Alignment

    public init(font: UIFont, color: UIColor, shadow: Shadow, alignment: Alignment) {
      self.font = font
      self.color = color
      self.shadow = shadow
      self.alignment = alignment
    }

    public struct Shadow {
      let opacity: Float
      let color: UIColor

      public init(opacity: Float, color: UIColor) {
        self.opacity = opacity
        self.color = color
      }
    }

    public enum Alignment {
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
  }

  public init(
    wordStyle: CaptionWordStyle,
    lineStyle: CaptionLineStyle,
    backgroundStyle: CaptionBackgroundStyle,
    backgroundColor: UIColor,
    textStyle: TextStyle
  ) {
    self.wordStyle = wordStyle
    self.lineStyle = lineStyle
    self.backgroundStyle = backgroundStyle
    self.backgroundColor = backgroundColor
    self.textStyle = textStyle
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
