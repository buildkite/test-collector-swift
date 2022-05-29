import XCTest

enum TestResult {
  case passed
  case failed
  case skipped
}

extension XCTestCase {
  /// The result for the test if it has completed.
  var result: TestResult? {
    guard let testRun = self.testRun else { return nil }
    if testRun.hasBeenSkipped == true { return .skipped }
    return testRun.hasSucceeded ? .passed : .failed
  }
}
