@testable import Core
import XCTest

class XCTestHelpersTests: XCTestCase {
  func testTestName() {
    XCTAssertEqual("testTestName", XCTestCase.testName(of: self))
  }

  func testClassName() {
    XCTAssertEqual("XCTestHelpersTests", XCTestCase.className(of: self))
  }
}
