import XCTest

/// An object that captures test data and exports it in real time.
final class TestObserver: NSObject, XCTestObservation {
  let logger: Logger?
  let telemetry: TelemetryClient?
  let uuid: () -> UUID

  /// The state of the current test.
  var test: TestState?

  /// The id associated with the root span of the current test.
  var executionID: TelemetryClient.ExecutionID?

  /// Per-test execution tags, keyed by test case identity.
  private let executionTags = LockIsolated([ObjectIdentifier: [String: String]]())

  /// Creates a new test observer.
  ///
  /// - Parameters:
  ///   - logger: A logger.
  ///   - telemetry: The client for exporting OpenTelemetry spans.
  ///   - uuid: A closure that returns a unique id to associate with an executed test case.
  init(
    logger: Logger? = .init(),
    telemetry: TelemetryClient? = nil,
    uuid: @escaping () -> UUID = UUID.init
  ) {
    self.logger = logger
    self.telemetry = telemetry
    self.uuid = uuid
  }

  /// Sets a tag on the execution for the given test case.
  ///
  /// - Parameters:
  ///   - testCase: The test case to tag.
  ///   - key: The tag key.
  ///   - value: The tag value.
  func setTag(for testCase: XCTestCase, key: String, value: String) {
    let id = ObjectIdentifier(testCase)
    self.executionTags.withValue { tags in
      guard tags[id] != nil else { return }
      tags[id]?[key] = value
    }
  }

  /// Notifies the observer immediately before a test case begins executing.
  ///
  /// Called exactly once per test case.
  func testCaseWillStart(_ testCase: XCTestCase) {
    self.executionTags.withValue { $0[ObjectIdentifier(testCase)] = [:] }
    let test = TestState(
      id: self.uuid(),
      className: XCTestCase.className(of: testCase),
      testName: XCTestCase.testName(of: testCase)
    )
    self.test = test
    self.executionID = self.telemetry?.startExecution(test)
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
    let context = SourceCodeContext(
      filePath: filePath ?? "<unknown>",
      fileName: String(filePath?.split(separator: "/").last ?? "<unknown>"),
      line: lineNumber
    )
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
    let tags = self.executionTags.withValue { tags -> [String: String]? in
      let result = tags.removeValue(forKey: ObjectIdentifier(testCase))
      return result?.isEmpty == true ? nil : result
    }
    defer {
      executionID = nil
      test = nil
    }
    guard let executionID = self.executionID, var test = self.test else { return }

    test.result = testCase.result
    self.telemetry?.finishExecution(executionID, test: test, tags: tags)
  }

  /// Notifies the observer immediately after all tests in a test bundle finish executing.
  ///
  /// Called exactly once per test bundle.
  ///
  /// - Note: The test process will generally exit after this method returns, so it must block until all asynchronous
  /// work is complete.
  func testBundleDidFinish(_ testBundle: Bundle) {
    self.telemetry?.forceFlush()
    self.logger?.waitForLogs()
  }

  func annotate(_ content: String) {
    guard let executionID = self.executionID else { return }
    self.telemetry?.annotate(content, executionID: executionID)
  }
}
