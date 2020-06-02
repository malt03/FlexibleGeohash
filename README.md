# FlexibleGeohash [![Build Status](https://travis-ci.org/malt03/FlexibleGeohash.svg?branch=master)](https://travis-ci.org/malt03/FlexibleGeohash) [![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-4BC51D.svg)](https://github.com/apple/swift-package-manager) ![Cocoapods](https://img.shields.io/cocoapods/v/FlexibleGeohash) ![License](https://img.shields.io/github/license/malt03/FlexibleGeohash.svg)

FlexibleGeohash is a very fast library for handling [Geohash](https://en.wikipedia.org/wiki/Geohash).  
Geohash is usually encoded in base32, but it can be encoded in base2/4/8/16/32.

I used [mmcloughlin/geohash](https://github.com/mmcloughlin/geohash) and [michael-groble/Geohash](https://github.com/michael-groble/Geohash) as a reference to create this library.  
Thank you so much!

## Benchmark
https://gist.github.com/malt03/7ac251ea0f47f4874c986a6720be3acf

### decode 1,000,000 times
|library|time|
|:--|:--|
|malt03/FlexibleGeohash|0.9568190574645996|
|[maximveksler/GeohashKit](https://github.com/maximveksler/GeohashKit)|1.2289820909500122|
|[michael-groble/Geohash](https://github.com/michael-groble/Geohash)|1.4453539848327637|
|[nh7a/Geohash](https://github.com/nh7a/Geohash)|9.60263705253601|

### encode 1,000,000 times
|library|time|
|:--|:--|
|malt03/FlexibleGeohash|0.22908806800842285|
|[maximveksler/GeohashKit](https://github.com/maximveksler/GeohashKit)|0.9335179328918457|
|[michael-groble/Geohash](https://github.com/michael-groble/Geohash)|0.3671489953994751|
|[nh7a/Geohash](https://github.com/nh7a/Geohash)|114.44236898422241|

### get neighbors 100,000 times
|library|time|
|:--|:--|
|malt03/FlexibleGeohash|0.33184492588043213|
|[maximveksler/GeohashKit](https://github.com/maximveksler/GeohashKit)|3.7601670026779175|
|[michael-groble/Geohash](https://github.com/michael-groble/Geohash)|0.33417296409606934|
|[nh7a/Geohash](https://github.com/nh7a/Geohash)|103.8870279788971|

## Usage
### Encoding
```swift
let appleCoordinate = CLLocationCoordinate2D(latitude: 37.331667, longitude: -122.030833)
var apple = Geohash(coordinate: appleCoordinate, precision: 7)
_ = apple.hash() // 9q9hrh5
apple.precision = 4
_ = apple.hash() // 9q9h
apple.precision = 10
_ = apple.hash() // 9q9hrh5ber
```

### Decoding
```swift
var apple = Geohash(hash: "9q9hrh5")
print(apple.region().mk())
// MKCoordinateRegion(
//     center: CLLocationCoordinate2D(latitude: 37.33222961425781, longitude: -122.03132629394531),
//     span: MKCoordinateSpan(latitudeDelta: 0.001373291015625, longitudeDelta: 0.001373291015625)
// )
apple.precision = 1
print(apple.region().mk())
// MKCoordinateRegion(
//     center: CLLocationCoordinate2D(latitude: 59.83154296875, longitude: -99.53201293945312),
//     span: __C.MKCoordinateSpan(latitudeDelta: 45.0, longitudeDelta: 45.0)
// )
```

### Getting neighbors
```swift
var apple = Geohash(hash: "9q9h")
_ = apple.neighbor(.north).hash() // 9q9j
_ = apple.neighbors().map { $0.hash() } // ["9q9k", "9q9m", "9q97", "9q9j", "9q95", "9q8u", "9q8v", "9q8g"]
apple.precision = 1
_ = apple.neighbors().map { $0.hash() } // ["d", "f", "6", "c", "3", "8", "b", "2"]
apple.precision = 7
_ = apple.neighbors().map { $0.hash() } // ["9q9h001", "9q9h003", "9q95bpc", "9q9h002", "9q95bpb", "9q8upbp", "9q8upbr", "9q8gzzz"]
```

### Using with base8
Naturally, Geohash encoded by something other than base32 is **not** compatible with the one encoded by base32.
```swift
let appleCoordinate = CLLocationCoordinate2D(latitude: 37.331667, longitude: -122.030833)
var apple = Geohash(coordinate: appleCoordinate, precision: 21, encoding: .base8)
_ = apple.hash() // 233114136012515572573
apple.precision = 4
_ = apple.hash() // 2331

apple.encoding = .base32
apple.precision = 12
_ = apple.hash() // 9q9hrh5berpg

_ = Geohash(hash: "2331", encoding: .base8).region().mk()
// MKCoordinateRegion(
//     center: CLLocationCoordinate2D(latitude: 37.96875, longitude: -120.9375),
//     span: MKCoordinateSpan(latitudeDelta: 2.8125, longitudeDelta: 5.625)
// )
```

### Getting Span for precision
```swift
_ = Geohash.span(precision: 7) // latitude: 0.001373291015625, longitude: 0.001373291015625
_ = Geohash.span(precision: 7, encoding: .base2) // latitude: 22.5, longitude: 22.5
```

### Setting default precision / encoding
```swift
Geohash.defaultPrecision = 4
Geohash.defaultEncoding = .base2
_ = Geohash(coordinate: LatLng(37.331667, -122.030833)).hash() // "0100"
_ = Geohash(hash: "0100").region().mk()
// MKCoordinateRegion(
//     center: CLLocationCoordinate2D(latitude: 22.5, longitude: -135),
//     span: MKCoordinateSpan(latitudeDelta: 45, longitudeDelta: 90)
// )
```

## Installation

### [SwiftPM](https://github.com/apple/swift-package-manager) (Recommended)

- On Xcode, click `File` > `Swift Packages` > `Add Package Dependency...`
- Input `https://github.com/malt03/FlexibleGeohash.git`

### [CocoaPods](https://github.com/cocoapods/cocoapods)

- Insert `pod 'FlexibleGeohash'` to your Podfile.
- Run `pod install`.
