import XCTest
@testable import FlexibleGeohash

final class FlexibleGeohashTests: XCTestCase {
    struct TestCase: Decodable {
        let hash: String
        let lat: Double
        let lng: Double
    }
    
    func test() {
        let testData = try! Data(contentsOf: Bundle(for: type(of: self)).url(forResource: "test_cases", withExtension: "json")!)
        let testCases = try! JSONDecoder().decode([TestCase].self, from: testData)
        for testCase in testCases {
            XCTAssertEqual(Geohash(lat: testCase.lat, lng: testCase.lng).encode(), testCase.hash)
        }
    }
}
