# SDWebImageJPEGXLCoder

[![Version](https://img.shields.io/cocoapods/v/SDWebImageJPEGXLCoder.svg?style=flat)](http://cocoapods.org/pods/SDWebImageJPEGXLCoder)
[![License](https://img.shields.io/cocoapods/l/SDWebImageJPEGXLCoder.svg?style=flat)](http://cocoapods.org/pods/SDWebImageJPEGXLCoder)
[![Platform](https://img.shields.io/cocoapods/p/SDWebImageJPEGXLCoder.svg?style=flat)](http://cocoapods.org/pods/SDWebImageJPEGXLCoder)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager/)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/SDWebImage/SDWebImageJPEGXLCoder)

SDWebImageJPEGXLCoder is a coder plugin for SDWebImage, to supports [JPEG-XL](https://jpeg.org/jpegxl/) format.

See: [Why JPEG-XL](https://jpegxl.info/why-jxl.html)

This coder supports the HDR/SDR decoding, as well as JPEG-XL aniamted image.

## TODO

1. This coder supports animation via UIImageView/NSImageView, no SDAnimatedImageView currently (Because the current coder API need codec supports non-sequential frame decoding, but libjxl does not have. Will remove this limit in SDWebImage 6.0)
2. This coder does not supports JPEG-XL encoding (Because I have no time :))
3. Apple's ImageIO supports JPEGXL decoding from iOS 17/tvOS 17/watchOS 10/macOS 14 (via: [WWDC2023](https://developer.apple.com/videos/play/wwdc2023/10122/)), so SDWebImage on those platform can also decode JPEGXL images using `SDImageIOCoder` (but no animated JPEG-XL support)

## Requirements

+ iOS 9.0
+ macOS 10.11
+ tvOS 9.0
+ watchOS 2.0
+ visionOS 1.0

## Installation

#### CocoaPods

SDWebImageJPEGXLCoder is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'SDWebImageJPEGXLCoder'
```

#### Carthage

SDWebImageJPEGXLCoder is available through [Carthage](https://github.com/Carthage/Carthage).

```
github "SDWebImage/SDWebImageJPEGXLCoder"
```

#### Swift Package Manager

SDWebImageJPEGXLCoder is available through [Swift Package Manager](https://swift.org/package-manager).

```swift
let package = Package(
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImageJPEGXLCoder.git", from: "0.1.0")
    ]
)
```

## Usage

### Add Coder

Before using SDWebImage to load JPEGXL images, you need to register the JPEGXL Coder to your coders manager. This step is recommended to be done after your App launch (like AppDelegate method).

+ Objective-C

```objective-c
// Add coder
SDImageJPEGXLCoder *JPEGXLCoder = [SDImageJPEGXLCoder sharedCoder];
[[SDImageCodersManager sharedManager] addCoder:JPEGXLCoder];
```

+ Swift

```swift
// Add coder
let JPEGXLCoder = SDImageJPEGXLCoder.shared
SDImageCodersManager.shared.addCoder(JPEGXLCoder)
```

### Loading

+ Objective-C

```objective-c
// JPEG-XL online image loading
NSURL *JPEGXLURL;
UIImageView *imageView;
[imageView sd_setImageWithURL:JPEGXLURL];
```

+ Swift

```swift
// JPEG-XL online image loading
let JPEGXLURL: URL
let imageView: UIImageView
imageView.sd_setImage(with: JPEGXLURL)
```

Note: You can also test animated JPEG-XL on UIImageView/NSImageView and WebImage (via SwiftUI port)

## Example

To run the example project, clone the repo, and run `pod install` from the root directory first. Then open `SDWebImageJPEGXLCoder.xcworkspace`.

This is a demo to show how to use JPEG-XL and animated JPEG-XL images via `SDWebImageJPEGXLCoderExample` target.

## Screenshot

<img src="https://raw.githubusercontent.com/SDWebImage/SDWebImageJPEGXLCoder/master/Example/Screenshot/JPEGXLDemo.png" width="300" />

These JPEG-XL images are from [JXL Art Gallery](https://jpegxl.info/art/)

## Author

[DreamPiggy](https://github.com/dreampiggy)

## License

SDWebImageJPEGXLCoder is available under the MIT license. See [the LICENSE file](https://github.com/SDWebImage/SDWebImageJPEGXLCoder/blob/master/LICENSE) for more info.

## Thanks

+ [libjxl](https://github.com/SDWebImage/libjxl-Xcode)

