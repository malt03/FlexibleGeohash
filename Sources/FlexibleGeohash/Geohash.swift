//
//  Geohash.swift
//  FlexibleGeohash
//
//  Created by Koji Murata on 2020/05/29.
//

import Foundation
import CoreLocation

public struct Geohash {
    public struct Bounding {
        let center: LatLng
        let span: LatLng
    }
    
    public enum Encoding: Int {
        case base2 = 1
        case base4
        case base8
        case base16
        case base32
    }
    
    private let latInt: UInt32
    private let lngInt: UInt32
    private let length: Int
    private let encoding: Encoding
    
    public init(coordinate: LatLngProtocol, length: Int = 12, encoding: Encoding = .base32) {
        latInt = Geohash.encodeRange(coordinate.latitude, 90)
        lngInt = Geohash.encodeRange(coordinate.longitude, 180)
        self.length = length
        self.encoding = encoding
    }
    
    public init(hash: String, encoding: Encoding = .base32) {
        let intHash = Geohash.decodeBase(hash, encoding: encoding)
        latInt = Geohash.squash(intHash)
        lngInt = Geohash.squash(intHash >> 1)
        length = hash.count
        self.encoding = encoding
    }
    
    public func encode() -> String {
        let intHash = Geohash.spread(latInt) | (Geohash.spread(lngInt) << 1)
        return Geohash.encodeBase(intHash, encoding: encoding, length: length)
    }
    
    public func decode() -> Bounding {
        let lat = Geohash.decodeRange(latInt, 90)
        let lng = Geohash.decodeRange(lngInt, 180)
        let error = Geohash.error(bitCount: length * encoding.rawValue)
        return Bounding(center: .init(lat + error.latitude / 2, lng + error.longitude / 2), span: error)
    }
    
    private static func error(bitCount: Int) -> LatLng {
        let latBitCount = bitCount / 2
        let lngBitCount = bitCount - latBitCount
        return .init(scalbn(180.0, -latBitCount), scalbn(360.0, -lngBitCount))
    }

    private static let exp232: Double = exp2(32)
    
    private static func encodeRange(_ x: Double, _ r: Double) -> UInt32 {
        let p = (x + r) / (2 * r)
        return UInt32(p * exp232)
    }
    
    private static func decodeRange(_ x: UInt32, _ r: Double) -> Double {
        let p = Double(x) / exp232
        return 2 * r * p - r
    }
    
    private static func spread(_ x: UInt32) -> UInt64 {
        var r = UInt64(x)
        r = (r | (r << 16)) & 0x0000ffff0000ffff
        r = (r | (r << 8)) & 0x00ff00ff00ff00ff
        r = (r | (r << 4)) & 0x0f0f0f0f0f0f0f0f
        r = (r | (r << 2)) & 0x3333333333333333
        r = (r | (r << 1)) & 0x5555555555555555
        return r
    }
    
    private static func squash(_ x: UInt64) -> UInt32 {
        var r = x
        r &= 0x5555555555555555
        r = (r | (r >> 1)) & 0x3333333333333333
        r = (r | (r >> 2)) & 0x0f0f0f0f0f0f0f0f
        r = (r | (r >> 4)) & 0x00ff00ff00ff00ff
        r = (r | (r >> 8)) & 0x0000ffff0000ffff
        r = (r | (r >> 16)) & 0x00000000ffffffff
        return UInt32(r)
    }
    
    private static let lookup = [Character]("0123456789bcdefghjkmnpqrstuvwxyz")
    private static func encodeBase(_ value: UInt64, encoding: Encoding, length: Int) -> String {
        let mask = (0..<encoding.rawValue).reduce(0 as UInt64, { $0 | 1 << $1 })
        return String(
            stride(from: 64 - encoding.rawValue * length, to: 64, by: encoding.rawValue).reversed().map { (i) -> Character in
                lookup[Int(value >> i & mask)]
            }
        )
    }
    private static func decodeBase(_ value: String, encoding: Encoding) -> UInt64 {
        let mask = (0..<encoding.rawValue).reduce(0 as UInt64, { $0 | 1 << $1 })
        let decoded = value.reversed().enumerated().reduce(0) { (result, char) -> UInt64 in
            guard let index = lookup.firstIndex(of: char.element) else { return 0 }
            return ((mask & UInt64(index)) << (char.offset * encoding.rawValue)) | result
        }
        return decoded << (64 - value.count * encoding.rawValue)
    }
}
