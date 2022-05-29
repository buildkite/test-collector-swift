struct SourceCodeLocation {
  var filePath: String
  var line: UInt
}

#if canImport(ObjectiveC)
import XCTest

extension SourceCodeLocation {
  init(_ location: XCTSourceCodeLocation) {
    self.filePath = location.fileURL.path
    self.line = UInt(location.lineNumber)
  }
}
#endif
