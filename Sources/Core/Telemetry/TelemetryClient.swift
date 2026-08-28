import Foundation

struct TelemetryClient {
  typealias ExecutionID = UUID

  private let start: (TestState) -> ExecutionID
  private let annotateExecution: (ExecutionID, String) -> Void
  private let finish: (ExecutionID, TestState, [String: String]?) -> Void
  private let flushPending: () -> Void

  init(
    start: @escaping (TestState) -> ExecutionID,
    annotate: @escaping (ExecutionID, String) -> Void,
    finish: @escaping (ExecutionID, TestState, [String: String]?) -> Void,
    flush: @escaping () -> Void
  ) {
    self.start = start
    self.annotateExecution = annotate
    self.finish = finish
    self.flushPending = flush
  }

  func startExecution(_ test: TestState) -> ExecutionID {
    self.start(test)
  }

  func annotate(_ content: String, executionID: ExecutionID) {
    self.annotateExecution(executionID, content)
  }

  func finishExecution(
    _ executionID: ExecutionID,
    test: TestState,
    tags: [String: String]?
  ) {
    self.finish(executionID, test, tags)
  }

  func forceFlush() {
    self.flushPending()
  }
}
