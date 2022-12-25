import XCTest

/// An object that captures test data and uploads it in real time.
class TestObserver: NSObject, XCTestObservation {
  let logger: Logger?
  let tracer: Tracer
  let uploader: UploadClient?
  let uuid: () -> UUID

  /// The state of the current test.
  var test: TestState?

  /// The id associated with the root span of the current test.
  var spanId: AnyHashable?

  /// Creates a new test observer.
  ///
  /// - Parameters:
  ///   - logger: A logger.
  ///   - tracer: The tracer for recording span data.
  ///   - uploader: The upload client for uploading test results
  ///   - uuid: A closure that returns a unique id to associate with an executed test case.
  init(
    logger: Logger? = .init(),
    tracer: Tracer = .live(),
    uploader: UploadClient? = nil,
    uuid: @escaping () -> UUID = UUID.init
  ) {
    self.logger = logger
    self.tracer = tracer
    self.uploader = uploader
    self.uuid = uuid
  }

  /// Notifies the observer immediately before a test case begins executing.
  ///
  /// Called exactly once per test case.
  func testCaseWillStart(_ testCase: XCTestCase) {
    self.spanId = self.tracer.startSpan(section: "top")
    self.test = TestState(
      id: self.uuid(),
      className: testCase.caseName,
      testName: testCase.testName
    )
  }

  #if canImport(ObjectiveC)
  /// Notifies the observer when a test case reports an issue.
  ///
  /// Called for each test failure that occurs at any point between test case start and finish.
  func testCase(_ testCase: XCTestCase, didRecord issue: XCTIssue) {
    self.test?.issues.append(TestIssue(issue))
  }
  #else
  /// Notifies the observer when a test case reports a failure.
  ///
  /// Called for each test failure that occurs at any point between test case start and finish.
  func testCase(
    _ testCase: XCTestCase,
    didFailWithDescription description: String,
    inFile filePath: String?,
    atLine lineNumber: Int
  ) {
    let context = SourceCodeContext(filePath: filePath ?? "<unknown>", line: lineNumber)
    self.test?.issues.append(TestIssue(description, context: context))
  }
  #endif

  #if canImport(ObjectiveC)
  /// Notifies the observer when a test suite records an expected failure.
  ///
  /// Called for each expected test failure that occurs at any point between test case start and finish.
  func testCase(_ testCase: XCTestCase, didRecord expectedFailure: XCTExpectedFailure) {
    self.test?.expectedFailures.append(ExpectedFailure(expectedFailure))
  }
  #endif

  /// Notifies the observer immediately after a test case finishes executing.
  ///
  /// Called exactly once per test case.
  func testCaseDidFinish(_ testCase: XCTestCase) {
    defer {
      spanId = nil
      test = nil
    }
    guard
      let span = self.spanId.map(self.tracer.endSpan(id:)),
      var test = self.test
    else { return }

    test.result = testCase.result

    let trace = Trace(test: test, span: span)

    self.uploader?.upload(trace: trace)
  }

  /// Notifies the observer immediately after all tests in a test bundle finish executing.
  ///
  /// Called exactly once per test bundle.
  ///
  /// - Note: The test process will generally exit after this method returns, so it must block until all asynchronous work is complete.
  func testBundleDidFinish(_ testBundle: Bundle) {
    self.uploader?.waitForUploads()
    self.logger?.waitForLogs()
  }
}
