/// A type containing the span information and result of a test
struct Trace: Equatable {
  /// A unique identifier.
  var id: String

  /// The scope of the test.
  ///
  /// In XCTest this is usually the type name of an XCTestCase.
  var scope: String?

  /// The name of the test.
  ///
  /// In XCTest this is usually a method of an XCTestCase.
  var name: String?

  /// The source location of the test.
  var location: String?

  /// The name of the file containing the test.
  var fileName: String?

  /// The result of the test.
  var result: Result?

  /// A short description of the failure.
  var failureReason: String?

  /// An array of additional details related failures.
  var failureExpanded: [FailureExpanded] = []

  /// The span for the duration of the test.
  var history: Span
}

extension Trace: Encodable {
  enum CodingKeys: String, CodingKey {
    case id
    case scope
    case name
    case location
    case fileName = "file_name"
    case result
    case failureReason = "failure_reason"
    case failureExpanded = "failure_expanded"
    case history
  }
}

extension Trace {
  init(test: TestState, span: Span) {
    self.id = test.id.uuidString
    self.scope = test.className
    self.name = test.testName
    self.result = test.result.map(Trace.Result.init) ?? .failed
    self.failureReason = test.issues.first?.compactDescription
    self.failureExpanded = test.issues.map(Trace.FailureExpanded.init(issue:))
    self.history = span
  }
}
