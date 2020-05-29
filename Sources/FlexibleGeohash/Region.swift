//
//  Region.swift
//  FlexibleGeohash
//
//  Created by Koji Murata on 2020/05/29.
//

import Foundation

public struct Region {
    let center: LatLng
    let span: LatLng
    
    public init(center: LatLng, span: LatLng) {
        self.center = center
        self.span = span
    }
}
