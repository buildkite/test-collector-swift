import Foundation

struct TestState {
  var id: UUID
  var className: String
  var testName: String
  var result: TestResult?
  var issues: [TestIssue] = []
  var expectedFailures: [ExpectedFailure] = []
}
