import Foundation

struct TestState {
  var id: UUID
  var className: String
  var testName: String
  var startDate: Date? // TODO: start/stop dates are no longer being used should we remove them?
  var stopDate: Date?
  var result: TestResult?
  var issues: [TestIssue] = []
  var expectedFailures: [ExpectedFailure] = []

  var totalDuration: TimeInterval? {
    guard let stop = stopDate, let start = startDate else { return nil }
    return stop.timeIntervalSince(start)
  }
}
