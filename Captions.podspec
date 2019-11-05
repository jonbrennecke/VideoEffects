version = '0.0.5'

source = { :git => 'https://github.com/jonbrennecke/captions.git' }
source[:commit] = `git rev-parse HEAD`.strip
source[:tag] = "v#{version}"

Pod::Spec.new do |s|
  s.name                   = "Captions"
  s.version                = version
  s.homepage               = "https://github.com/jonbrennecke/captions"
  s.author                 = "Jon Brennecke"
  s.platforms              = { :ios => "9.0" }
  s.source                 = source
  s.cocoapods_version      = ">= 1.2.0"
  s.license                = 'MIT'
  s.summary                = 'Swift library for rendering animated captions/subtitles'
  s.source_files           = 'captions/**/*.swift'
  s.swift_version          = '5'
end
