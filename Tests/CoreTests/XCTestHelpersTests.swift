@testable import Core
import XCTest

class XCTestHelpersTests: XCTestCase {
  func testTestName() {
    XCTAssertEqual("testTestName", self.testName)
  }

  func testCaseName() {
    XCTAssertEqual("XCTestHelpersTests", self.caseName)
  }
}
