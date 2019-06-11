import XCTest
@testable import MongoKitten

final class MongoKittenTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(MongoKitten().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
