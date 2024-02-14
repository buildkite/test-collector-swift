struct SourceCodeLocation {
  var fileURL: URL
  var line: UInt
}

#if canImport(ObjectiveC)
import XCTest

extension SourceCodeLocation {
  init(_ location: XCTSourceCodeLocation) {
    self.fileURL = location.fileURL
    self.line = UInt(location.lineNumber)
  }
}
#endif
