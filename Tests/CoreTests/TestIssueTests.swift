@testable import Core
import XCTest

class TestIssueTests: XCTestCase {
  static var observer: TestObserver!

  override class func setUp() {
    Self.observer = Collector().observer
    XCTestObservationCenter.shared.addTestObserver(Self.observer)
  }

  func testCurrentTest() {
    XCTAssertNotNil(Self.observer.test)
  }

  override class func tearDown() {
    XCTestObservationCenter.shared.removeTestObserver(Self.observer)
  }
}
