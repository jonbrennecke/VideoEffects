import AVFoundation

@available(iOS 11.0, *)
internal func createDepthData(with imageSource: CGImageSource) -> AVDepthData? {
  if
    let disparityInfo = CGImageSourceCopyAuxiliaryDataInfoAtIndex(
      imageSource, 0, kCGImageAuxiliaryDataTypeDisparity
    ) as? [AnyHashable: Any],
    let depthData = try? AVDepthData(fromDictionaryRepresentation: disparityInfo) {
    return depthData
  }

  if
    let depthInfo = CGImageSourceCopyAuxiliaryDataInfoAtIndex(
      imageSource, 0, kCGImageAuxiliaryDataTypeDepth
    ) as? [AnyHashable: Any],
    let depthData = try? AVDepthData(fromDictionaryRepresentation: depthInfo) {
    return depthData
  }

  return nil
}

@available(iOS 12.0, *)
internal func createSegmentationMatte(with imageSource: CGImageSource) -> AVPortraitEffectsMatte? {
  if
    let info = CGImageSourceCopyAuxiliaryDataInfoAtIndex(
      imageSource, 0, kCGImageAuxiliaryDataTypePortraitEffectsMatte
    ) as? [AnyHashable: Any],
    let matte = try? AVPortraitEffectsMatte(fromDictionaryRepresentation: info) {
    return matte
  }
  return nil
}

internal func createImage(with imageSource: CGImageSource) -> CGImage? {
  return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
}

internal func createImageSource(with data: Data) -> CGImageSource? {
  guard
    let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
    case .statusComplete = CGImageSourceGetStatus(imageSource),
    CGImageSourceGetCount(imageSource) > 0
  else {
    return nil
  }
  return imageSource
}
