version = '0.0.33'

Pod::Spec.new do |s|
  s.name                   = 'VideoEffects'
  s.version                = version
  s.homepage               = 'https://github.com/jonbrennecke/video-effects'
  s.author                 = 'Jon Brennecke'
  s.platforms              = { :ios => '13.2' } 
  s.source                 = { :git => 'https://github.com/jonbrennecke/video-effects.git', :tag => "v#{version}" }
  s.cocoapods_version      = '>= 1.2.0'
  s.license                = 'MIT'
  s.summary                = 'Swift library for rendering videos with effects'
  s.source_files           = 'VideoEffects/**/*.swift'
  s.swift_version          = '5'
  s.dependency 'ImageUtils'
end
