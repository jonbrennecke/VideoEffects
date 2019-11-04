source = { :git => 'https://github.com/jonbrennecke/captions.git' }
source[:commit] = `git rev-parse HEAD`.strip

Pod::Spec.new do |s|
  s.name                   = "Captions"
  s.version                = version
  s.homepage               = "https://github.com/jonbrennecke/captions"
  s.author                 = "Jon Brennecke"
  s.platforms              = { :ios => "9.0", :tvos => "9.2" }
  s.source                 = source
  s.cocoapods_version      = ">= 1.2.0"
end
