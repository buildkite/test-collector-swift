import XCTest

extension XCTestCase {
  func sleep(for seconds: TimeInterval) {
    let expectation = self.expectation(description: "Sleep")
    expectation.isInverted = true
    self.wait(for: [expectation], timeout: seconds)
  }
}
