extension Trace {
  /// The result for the test associated with a trace.
  enum Result: String, Encodable, Equatable {
    case passed
    case failed
    case skipped
  }
}

extension Trace.Result {
  init(_ result: TestResult) {
    switch result {
    case .passed: self = .passed
    case .skipped: self = .skipped
    case .failed: self = .failed
    }
  }
}
