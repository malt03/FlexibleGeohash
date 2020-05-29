import XCTest
@testable import FlexibleGeohash

final class FlexibleGeohashTests: XCTestCase {
    struct EncodeTestCase: Decodable {
        let hash: String
        let lat: Double
        let lng: Double
    }
    
    struct DecodeTestCase: Decodable {
        let hash: String
        let region: Region
    }
    
    func testEncode() {
        let testData = try! Data(contentsOf: Bundle(for: type(of: self)).url(forResource: "encode_cases", withExtension: "json")!)
        let testCases = try! JSONDecoder().decode([EncodeTestCase].self, from: testData)
        for testCase in testCases {
            XCTAssertEqual(Geohash(coordinate: LatLng(testCase.lat, testCase.lng)).hash, testCase.hash)
        }
    }
    
    func testDecode() {
        let testData = try! Data(contentsOf: Bundle(for: type(of: self)).url(forResource: "decode_cases", withExtension: "json")!)
        let testCases = try! JSONDecoder().decode([DecodeTestCase].self, from: testData)
        for testCase in testCases {
            XCTAssertEqual(Geohash(hash: testCase.hash).region, testCase.region)
        }
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
