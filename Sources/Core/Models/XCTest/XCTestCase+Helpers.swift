import XCTest

extension XCTestCase {
  /// The name of the class containing the test.
  var caseName: String { "\(type(of: self))" }

  /// The name of the test.
  var testName: String {
    #if canImport(ObjectiveC)
    // [XCTestCase testName]
    return String(
      self.name
        .split(separator: " ", maxSplits: 1).last!
        .dropLast(self.name.last == "]" ? 1 : 0)
    )
    #else
    // XCTestCase.testName
    return String(self.name.split(separator: ".").last!)
    #endif
  }
}
