//
//  Geohash.swift
//  FlexibleGeohash
//
//  Created by Koji Murata on 2020/05/29.
//

import Foundation
import CoreLocation

public struct Geohash {
    public static var defaultEncoding = Encoding.base32
    public static var defaultPrecision = 12
    
    public enum Direction: Int, CaseIterable {
        case north
        case south
        case east
        case west
    }
    
    public enum Encoding: Int {
        case base2 = 1
        case base4
        case base8
        case base16
        case base32
        
        fileprivate func getMask() -> UInt64 {
            switch self {
            case .base2: return 0x01
            case .base4: return 0x03
            case .base8: return 0x07
            case .base16: return 0x0f
            case .base32: return 0x1f
            }
        }
    }
    
    public var precision: Int { didSet { bitCount = precision * encoding.rawValue } }
    public var encoding: Encoding { didSet { bitCount = precision * encoding.rawValue } }

    private let latInt: UInt32
    private let lngInt: UInt32
    private var bitCount: Int
    
    public init(coordinate: LatLngProtocol, precision: Int = defaultPrecision, encoding: Encoding = defaultEncoding) {
        latInt = Geohash.encodeRange(coordinate.latitude, 90)
        lngInt = Geohash.encodeRange(coordinate.longitude, 180)
        self.precision = precision
        self.encoding = encoding
        bitCount = precision * encoding.rawValue
    }
    
    public init(hash: String, encoding: Encoding = defaultEncoding) {
        precision = hash.count
        self.encoding = encoding
        bitCount = precision * encoding.rawValue
        let intHash = Geohash.decodeBase(hash, encoding: encoding, bitCount: bitCount)
        latInt = Geohash.squash(intHash)
        lngInt = Geohash.squash(intHash >> 1)
    }
    
    public init(bitHash: UInt64, precision: Int = defaultPrecision, encoding: Encoding = defaultEncoding) {
        let fullBitHash = bitHash << (64 - precision)
        self.latInt = Geohash.squash(fullBitHash)
        self.lngInt = Geohash.squash(fullBitHash >> 1)
        self.precision = precision
        self.encoding = encoding
        bitCount = precision * encoding.rawValue
    }
    
    private init(latInt: UInt32, lngInt: UInt32, precision: Int, encoding: Encoding) {
        self.latInt = latInt
        self.lngInt = lngInt
        self.precision = precision
        self.encoding = encoding
        bitCount = precision * encoding.rawValue
    }
    
    public func neighbor(_ direction: Direction) -> Geohash {
        switch direction {
        case .north:
            return Geohash(
                latInt: self.latInt &+ (1 << (32 - bitCount / 2)),
                lngInt: lngInt,
                precision: precision,
                encoding: encoding
            )
        case .south:
            return Geohash(
                latInt: self.latInt &- (1 << (32 - bitCount / 2)),
                lngInt: lngInt,
                precision: precision,
                encoding: encoding
            )
        case .east:
            return Geohash(
                latInt: self.latInt,
                lngInt: self.lngInt &+ (1 << (32 - (bitCount - bitCount / 2))),
                precision: precision,
                encoding: encoding
            )
        case .west:
            return Geohash(
                latInt: self.latInt,
                lngInt: self.lngInt &- (1 << (32 - (bitCount - bitCount / 2))),
                precision: precision,
                encoding: encoding
            )
        }
    }
    
    public func neighbors() -> [Geohash] {
        return [
            neighbor(.east),
            neighbor(.east).neighbor(.north),
            neighbor(.east).neighbor(.south),
            neighbor(.north),
            neighbor(.south),
            neighbor(.west),
            neighbor(.west).neighbor(.north),
            neighbor(.west).neighbor(.south),
        ]
    }
    
    public func hash() -> String {
        return Geohash.encodeBase(fullBitHash(), encoding: encoding, bitCount: bitCount)
    }
    
    public func bitHash() -> UInt64 {
        fullBitHash() >> (64 - bitCount)
    }
    
    private func fullBitHash() -> UInt64 {
        Geohash.spread(latInt) | (Geohash.spread(lngInt) << 1)
    }

    public func region() -> Region {
        let lat = Geohash.decodeRange(latInt, 90, bitCount: bitCount / 2)
        let lng = Geohash.decodeRange(lngInt, 180, bitCount: bitCount - bitCount / 2)
        let span = Geohash.span(bitCount: bitCount)
        return Region(center: .init(lat + span.latitude / 2, lng + span.longitude / 2), span: span)
    }
    
    public static func span(precision: Int = defaultPrecision, encoding: Encoding = defaultEncoding) -> LatLng {
        span(bitCount: precision * encoding.rawValue)
    }
    
    private static func span(bitCount: Int) -> LatLng {
        let latBitCount = bitCount / 2
        let lngBitCount = bitCount - latBitCount
        return .init(scalbn(180.0, -latBitCount), scalbn(360.0, -lngBitCount))
    }

    private static let exp232: Double = exp2(32)
    
    private static func encodeRange(_ x: Double, _ r: Double) -> UInt32 {
        let p = (x + r) / (2 * r)
        return UInt32(p * exp232)
    }
    
    private static func decodeRange(_ x: UInt32, _ r: Double, bitCount: Int) -> Double {
        let shift = 32 - bitCount
        let p = Double((x >> shift) << shift) / exp232
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
    private static let reverseLookup = lookup.enumerated().reduce(into: [Character: UInt64]()) { $0[$1.element] = UInt64($1.offset) }
    private static func encodeBase(_ value: UInt64, encoding: Encoding, bitCount: Int) -> String {
        let mask = encoding.getMask()
        return (stride(from: encoding.rawValue, to: bitCount + 1, by: encoding.rawValue) as StrideTo<Int>)
            .reduce(into: "", { $0 += String(lookup[Int(value >> (64 - $1) & mask)]) })
    }
    private static func decodeBase(_ value: String, encoding: Encoding, bitCount: Int) -> UInt64 {
        let mask = encoding.getMask()
        let decoded = value.reversed().enumerated().reduce(0) { (result, char) -> UInt64 in
            let index = reverseLookup[char.element]!
            return ((mask & UInt64(index)) << (char.offset * encoding.rawValue)) | result
        }
        return decoded << (64 - bitCount)
    }
}
