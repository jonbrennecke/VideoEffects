VideoEffects
----

VideoEffects is a simple Swift library for playing and exporting videos with effects. The library supports many possible effects. For instance, you can crop a video into a square aspect ratio, or render a video with color adjustments like brightness, hue and saturation.

### Setting up effects

#### Color Controls

The `ColorControls` struct allows for adjustments to the color properties of the video. All properties are optional. 

```swift
let colorControls = EffectConfig.ColorControls(
  brightness: Double
  saturation: Double
  contrast: Double
  exposure: Double
  hue: Double
)
```

#### Effect Configuration

The `EffectConfig` struct defines the effecs applied to a video. For example:

```swift
let effects = EffectConfig(
  colorControls: EffectConfig.ColorControls(),
  aspectRatio: CGSize(width: 1, height: 1),
  timeRange: CMTimeRange(start: .zero, end: CMTime(seconds: 3, preferredTimescale: 600)),
  layer: layer
)
```

Effects can be:
- `colorControls`: Controls like hue, saturation, brightness, contrast and exposure.
- `aspectRatio`: The aspect ratio as a `CGSize`.
- `timeRange`: The time range of a video. Use this to trim the video.
- `layer`: A CALayer to render on top of the video. It can be any CALayer (not associated with a UIView).

All properties are optional. Omitted parameters will leave the video unchanged.

### Playing a video with effects

`EffectPlayerView` is a wrapper around `AVPlayer` that uses a custom compositor to render effects.

```swift
let asset = AVAsset(url: url)

// setup effects
let effects = EffectConfig(
  colorControls: EffectConfig.ColorControls(),
  aspectRatio: CGSize(width: 1, height: 1),
  timeRange: CMTimeRange(start: .zero, end: CMTime(seconds: 3, preferredTimescale: 600)),
  layer: layer
)

let effectView = EffectPlayerView()
effectView.effects = effects
effectView.asset = asset
```

### Exporting a video with effects

```swift
let asset = AVAsset(url: url)

// setup effects
let effects = effects = EffectConfig(
  colorControls: EffectConfig.ColorControls(),
  aspectRatio: CGSize(width: 1, height: 1),
  timeRange: CMTimeRange(start: .zero, end: CMTime(seconds: 3, preferredTimescale: 600)),
  layer: layer
)

// finally, export the video
let exportConfig = try! ExportConfig.defaultConfig()
export(asset: asset, effects: effects, config: exportConfig) { result in
  // result is of type Result<URL, Error>
}
```

### Running the example app

Open the workspace `VideoEffects.xcworkspace` and run the target `VideoEffects-example`.
