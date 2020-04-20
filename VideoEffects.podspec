version = '0.0.18'

source = { :git => 'https://github.com/jonbrennecke/video-effects.git' }
source[:commit] = `git rev-parse HEAD`.strip
source[:tag] = "v#{version}"

Pod::Spec.new do |s|
  s.name                   = 'Captions'
  s.version                = version
  s.homepage               = 'https://github.com/jonbrennecke/video-effects'
  s.author                 = 'Jon Brennecke'
  s.platforms              = { :ios => '9.0' }
  s.source                 = source
  s.cocoapods_version      = '>= 1.2.0'
  s.license                = 'MIT'
  s.summary                = 'Swift library for rendering videos with effects'
  s.source_files           = 'captions/**/*.swift'
  s.swift_version          = '5'
end
