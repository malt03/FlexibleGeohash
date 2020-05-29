//
//  MapKitExtension.swift
//  FlexibleGeohash
//
//  Created by Koji Murata on 2020/05/29.
//

#if canImport(MapKit)
import MapKit

extension CLLocationCoordinate2D: LatLngProtocol {}
extension LatLng {
    func clCoordinate() -> CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    func mkSpan() -> MKCoordinateSpan { .init(latitudeDelta: latitude, longitudeDelta: longitude) }
}
extension Region {
    public func mk() -> MKCoordinateRegion { .init(center: center.clCoordinate(), span: span.mkSpan()) }
}
#endif
