Video Effects
----

### Setting up effects

#### Color Controls

The ColorControls struct allows for adjustments to the color properties of the video. All properties are optional. 

```swift
let colorControls = EffectConfig.ColorControls(
  brightness: Double
  saturation: Double
  contrast: Double
  exposure: Double
  hue: Double
)
```

### Playing a video with effects

`EffectPlayerView` is a wrapper around `AVPlayer` that uses a custom compositor to render effects.

Note: The `layer` will be rendered on top of the video. It can be any CALayer (not associated with a UIView).

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
export(asset: asset, effects: effects, config: exportConfig) { result in
  // result is of type Result<URL, Error>
}
```

### Running the example app

Open the workspace `VideoEffects.xcworkspace` and run the target `VideoEffects-example`.
