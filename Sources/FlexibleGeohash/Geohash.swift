//
//  Geohash.swift
//  FlexibleGeohash
//
//  Created by Koji Murata on 2020/05/29.
//

import Foundation

public struct Geohash {
    public enum Encoding: Int {
        case base2 = 1
        case base4
        case base8
        case base16
        case base32
    }
    
    private let latInt: UInt32
    private let lngInt: UInt32
    
    public init(lat: Double, lng: Double) {
        latInt = Geohash.encodeRange(lat, 90)
        lngInt = Geohash.encodeRange(lng, 180)
    }
    
//    init(hash: String, encoding: Encoding = .base32) {
//
//    }
    
    public func encode(length: Int = 12, encoding: Encoding = .base32) -> String {
        let intHash = Geohash.spread(latInt) | (Geohash.spread(lngInt) << 1)
        return Geohash.encodeBase(intHash, encoding: encoding, length: length)
    }
        
    private static let exp232: Double = exp2(32)
    
    private static func encodeRange(_ x: Double, _ r: Double) -> UInt32 {
        let p = (x + r) / (2 * r)
        return UInt32(p * exp232)
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
    
    private static let lookup = [Character]("0123456789bcdefghjkmnpqrstuvwxyz")
    private static func encodeBase(_ value: UInt64, encoding: Encoding, length: Int) -> String {
        let mask = (0..<encoding.rawValue).reduce(0 as UInt64, { $0 | 1 << $1 })
        return String(
            stride(from: 64 - encoding.rawValue * length, to: 64, by: encoding.rawValue).reversed().map { (i) -> Character in
                lookup[Int(value >> i & mask)]
            }
        )
    }
}
