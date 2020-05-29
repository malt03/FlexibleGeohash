//
//  LatLng.swift
//  FlexibleGeohash
//
//  Created by Koji Murata on 2020/05/29.
//

import Foundation

public struct LatLng: LatLngProtocol {
    public let latitude: Double
    public let longitude: Double
    
    public init(_ latitude: Double, _ longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public protocol LatLngProtocol {
    var latitude: Double { get }
    var longitude: Double { get }
}
