# FlexibleGeohash

FlexibleGeohash is a very high performance library for handling Geohash.  
Geohash is usually encoded in base32, but it can be encoded in base2,4,8,16,32.

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
In many Geohash libraries, the neighbors function returns 8 hashes of around it.  
However, this library returns **9 values**, including its own.  
Because there is no performance disadvantage and in many cases it is easier to use.
```swift
var apple = Geohash(hash: "9q9h")
_ = apple.neighbor(.north).hash() // 9q9j
_ = apple.neighbors().map { $0.hash() } // ["9q9k", "9q9m", "9q97", "9q9j", "9q9h", "9q95", "9q8u", "9q8v", "9q8g"]
apple.precision = 1
_ = apple.neighbors().map { $0.hash() } // ["d", "f", "6", "c", "9", "3", "8", "b", "2"]
apple.precision = 7
_ = apple.neighbors().map { $0.hash() } // ["9q9h001", "9q9h003", "9q95bpc", "9q9h002", "9q9h000", "9q95bpb", "9q8upbp", "9q8upbr", "9q8gzzz"]
```

### Using with base8
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
