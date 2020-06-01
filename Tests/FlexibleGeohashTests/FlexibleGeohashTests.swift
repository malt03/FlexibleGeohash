import XCTest
@testable import FlexibleGeohash

protocol TestCase: Decodable {
    static var fileName: String { get }
}
extension TestCase {
    static func get() -> [Self] {
        let url = Bundle(for: FlexibleGeohashTests.self).url(forResource: fileName, withExtension: "json")!
        let testData = try! Data(contentsOf: url)
        return try! JSONDecoder().decode([Self].self, from: testData)
    }
}

final class FlexibleGeohashTests: XCTestCase {
    struct EncodeTestCase: TestCase {
        static var fileName: String { "encode_cases" }

        let hash: String
        let lat: Double
        let lng: Double
    }
    
    struct DecodeTestCase: TestCase {
        static var fileName: String { "decode_cases" }

        let hash: String
        let region: Region
    }
    
    struct NeighborsTestCase: TestCase {
        static var fileName: String { "neighbors_cases" }

        let hash: String
        let neighbors: [String]
    }
    
    func testEncode() {
        for testCase in EncodeTestCase.get() {
            XCTAssertEqual(Geohash(coordinate: LatLng(testCase.lat, testCase.lng), precision: 12).hash(), testCase.hash)
        }
    }

    func testEncodeAndRedecode() {
        for testCase in EncodeTestCase.get() {
            let coordinate = LatLng(testCase.lat, testCase.lng)
            let region = Geohash(coordinate: coordinate, precision: 12).region()
            XCTAssert(region.contains(coordinate: coordinate), "\(coordinate) is not contained in \(region)")
        }
    }

    func testDecode() {
        for testCase in DecodeTestCase.get() {
            XCTAssertEqual(Geohash(hash: testCase.hash).region(), testCase.region)
        }
    }

    func testDecodeAndRehash() {
        for testCase in DecodeTestCase.get() {
            let center = Geohash(hash: testCase.hash).region().center
            XCTAssertEqual(Geohash(coordinate: center, precision: testCase.hash.count).hash(), testCase.hash)
        }
    }

    func testNeighbors() {
        for testCase in NeighborsTestCase.get() {
            let neighbors = Geohash(hash: testCase.hash).neighbors().map { $0.hash() }
            XCTAssertEqual(Set(neighbors), Set(testCase.neighbors + [testCase.hash]))
        }
    }

    func testNeighbor() {
        for testCase in NeighborsTestCase.get() {
            let neighbor = Geohash(hash: testCase.hash).neighbor(.north).hash()
            XCTAssertEqual(neighbor, testCase.neighbors[0])
        }
    }
    
    func testChangePrecision() {
        var fullGeohash = Geohash(hash: String(repeating: "z", count: 12))
        fullGeohash.precision = 1
        XCTAssertEqual(fullGeohash.hash(), "z")
        fullGeohash.precision = 12
        XCTAssertEqual(fullGeohash.hash(), String(repeating: "z", count: 12))

        var singleGeohash = Geohash(hash: "z")
        singleGeohash.precision = 12
        XCTAssertEqual(singleGeohash.hash(), "z" + String(repeating: "0", count: 11))
        singleGeohash.precision = 1
        XCTAssertEqual(singleGeohash.hash(), "z")
    }
    
    func testEncoding() {
        var geohash = Geohash(hash: String(repeating: "1", count: 64), encoding: .base2)
        XCTAssertEqual(geohash.hash(), String(repeating: "1", count: 64))
        geohash.encoding = .base4
        geohash.precision = 32
        XCTAssertEqual(geohash.hash(), String(repeating: "3", count: 32))
        geohash.encoding = .base8
        geohash.precision = 21
        XCTAssertEqual(geohash.hash(), String(repeating: "7", count: 21))
        geohash.encoding = .base16
        geohash.precision = 16
        XCTAssertEqual(geohash.hash(), String(repeating: "g", count: 16))
        geohash.encoding = .base32
        geohash.precision = 12
        XCTAssertEqual(geohash.hash(), String(repeating: "z", count: 12))
    }
    
    func testBoundaryNeighbor() {
        do {
            let geohash = Geohash(hash: String(repeating: "0", count: 16), encoding: .base16)
            let neighbor = geohash.neighbor(.south).neighbor(.west)
            XCTAssertEqual(neighbor.hash(), String(repeating: "g", count: 16))
        }
        do {
            let geohash = Geohash(hash: "zzz", encoding: .base16)
            let neighbor = geohash.neighbor(.north).neighbor(.east)
            XCTAssertEqual(neighbor.hash(), "000")
        }
    }
    
    func testGettingSpan() {
        XCTAssertEqual(Geohash.span(precision: 1), LatLng(45, 45))
        XCTAssertEqual(Geohash.span(precision: 1, encoding: .base2), LatLng(180, 180))
    }
}

extension Region {
    func contains(coordinate: LatLng) -> Bool {
        ((center.latitude - span.latitude / 2)...(center.latitude + span.latitude / 2)).contains(coordinate.latitude) &&
            ((center.longitude - span.longitude / 2)...(center.longitude + span.longitude / 2)).contains(coordinate.longitude)
    }
}

extension Region: Decodable, Equatable {
    public static func == (lhs: Region, rhs: Region) -> Bool {
        lhs.center == rhs.center && lhs.span == rhs.span
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            center: try container.decode(LatLng.self, forKey: .center),
            span: try container.decode(LatLng.self, forKey: .span)
        )
    }
    
    enum CodingKeys: CodingKey {
        case center
        case span
    }
}

extension LatLng: Decodable, Equatable {
    public static func == (lhs: LatLng, rhs: LatLng) -> Bool {
        lhs.latitude.almostEqual(rhs.latitude) && lhs.longitude.almostEqual(rhs.longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            try container.decode(Double.self, forKey: .latitude),
            try container.decode(Double.self, forKey: .longitude)
        )
    }
    
    enum CodingKeys: CodingKey {
        case latitude
        case longitude
    }
}

extension Double {
    func almostEqual(_ other: Double) -> Bool {
        abs(self - other) < pow(0.1, 9)
    }
}
