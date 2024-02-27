#
# Be sure to run `pod lib lint SDWebImageJPEGXLCoder.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SDWebImageJPEGXLCoder'
  s.version          = '0.1.0'
  s.summary          = 'A SDWebImage coder plugin to support JPEG-XL image'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
A SDWebImage coder plugin to support JPEG-XL image
                       DESC

  s.homepage         = 'https://github.com/dreampiggy/SDWebImageJPEGXLCoder'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'dreampiggy' => 'lizhuoli1126@126.com' }
  s.source           = { :git => 'https://github.com/SDWebImage/SDWebImageJPEGXLCoder.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.11'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
  s.visionos.deployment_target = '1.0'

  s.source_files = 'SDWebImageJPEGXLCoder/Classes/**/*'
  
  s.dependency 'SDWebImage', "~> 5.12"
  s.dependency 'libjxl'
end
