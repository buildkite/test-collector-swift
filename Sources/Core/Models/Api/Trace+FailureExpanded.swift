extension Trace {
  /// A type containing details related to a test failure that occurred during a trace.
  struct FailureExpanded: Encodable, Equatable {
    /// An array of strings containing a line separated failure message or additional details.
    var expanded: [String]

    /// An array of strings representing frames on the call stack when the failure occurred.
    var backtrace: [String]
  }
}

extension Trace.FailureExpanded {
  init(issue: TestIssue) {
    self.expanded = issue.description.components(separatedBy: "\n")
    self.backtrace = issue.sourceCodeContext.callStack.enumerated().map { "\($0) \($1)" }
  }
}
