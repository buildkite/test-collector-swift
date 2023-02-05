import XCTest

extension XCTestCase {
  /// Returns the class name of the test.
  static func className(of testCase: XCTestCase) -> String {
    "\(type(of: testCase))"
  }

  /// Returns the name of the test.
  static func testName(of testCase: XCTestCase) -> String {
    #if canImport(ObjectiveC)
    // [XCTestCase testName]
    return String(
      testCase.name
        .split(separator: " ", maxSplits: 1).last!
        .dropLast(testCase.name.last == "]" ? 1 : 0)
    )
    #else
    // XCTestCase.testName
    return String(testCase.name.split(separator: ".").last!)
    #endif
  }
}
