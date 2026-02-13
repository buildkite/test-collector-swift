import XCTest

extension XCTestCase {
  /// Tags this test execution with a key-value pair.
  ///
  /// Tags are included in the uploaded test results and can be used to filter and group tests in Test Engine.
  ///
  /// - Parameters:
  ///   - key: The tag key.
  ///   - value: The tag value.
  public func tagExecution(_ key: String, _ value: String) {
    TestCollector.shared?.tagExecution(testCase: self, key: key, value: value)
  }
}
