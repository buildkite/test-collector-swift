struct ExpectedFailure {
  var failureReason: String?
  var issue: TestIssue
}

#if canImport(ObjectiveC)
import XCTest

extension ExpectedFailure {
  init(_ expectedFailure: XCTExpectedFailure) {
    self.failureReason = expectedFailure.failureReason
    self.issue = TestIssue(expectedFailure.issue)
  }
}
#endif
