//
//  Geohash.swift
//  FlexibleGeohash
//
//  Created by Koji Murata on 2020/05/29.
//

import Foundation
import CoreLocation

public struct Geohash {
    public enum Direction: CaseIterable {
        case n
        case ne
        case e
        case se
        case s
        case sw
        case w
        case nw
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
    
    private let latInt: UInt32
    private let lngInt: UInt32
    private let precision: Int
    private let encoding: Encoding
    private let bitCount: Int
    
    public init(coordinate: LatLngProtocol, precision: Int = 12, encoding: Encoding = .base32) {
        latInt = Geohash.encodeRange(coordinate.latitude, 90)
        lngInt = Geohash.encodeRange(coordinate.longitude, 180)
        self.precision = precision
        self.encoding = encoding
        bitCount = precision * encoding.rawValue
    }
    
    public init(hash: String, encoding: Encoding = .base32) {
        precision = hash.count
        self.encoding = encoding
        bitCount = precision * encoding.rawValue
        let intHash = Geohash.decodeBase(hash, encoding: encoding, bitCount: bitCount)
        latInt = Geohash.squash(intHash)
        lngInt = Geohash.squash(intHash >> 1)
    }
    
    private init(latInt: UInt32, lngInt: UInt32, precision: Int, encoding: Encoding) {
        self.latInt = latInt
        self.lngInt = lngInt
        self.precision = precision
        self.encoding = encoding
        bitCount = precision * encoding.rawValue
    }
    
    public func getNeighbor(direction: Direction) -> Geohash {
        let latInt: UInt32
        switch direction {
        case .e, .w: latInt = self.latInt
        case .n, .ne, .nw:
            latInt = Geohash.encodeRange(region().center.latitude + region().span.latitude, 90)
        case .s, .se, .sw:
            latInt = Geohash.encodeRange(region().center.latitude - region().span.latitude, 90)
        }
        let lngInt: UInt32
        switch direction {
        case .n, .s: lngInt = self.lngInt
        case .e, .ne, .se:
            lngInt = Geohash.encodeRange(region().center.longitude + region().span.longitude, 180)
        case .w, .nw, .sw:
            lngInt = Geohash.encodeRange(region().center.longitude - region().span.longitude, 180)
        }
        return Geohash(latInt: latInt, lngInt: lngInt, precision: precision, encoding: encoding)
    }
    
    public func neighbors() -> [Geohash] {
        Direction.allCases.map { getNeighbor(direction: $0) }
    }
    
    public func hash() -> String {
        let intHash = Geohash.spread(latInt) | (Geohash.spread(lngInt) << 1)
        return Geohash.encodeBase(intHash, encoding: encoding, bitCount: bitCount)
    }
    
    public func region() -> Region {
        let lat = Geohash.decodeRange(latInt, 90)
        let lng = Geohash.decodeRange(lngInt, 180)
        let error = Geohash.error(bitCount: bitCount)
        return Region(center: .init(lat + error.latitude / 2, lng + error.longitude / 2), span: error)
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
