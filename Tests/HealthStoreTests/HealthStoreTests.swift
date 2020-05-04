import XCTest
@testable import HealthStore

final class HealthStoreTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(HealthStore().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
