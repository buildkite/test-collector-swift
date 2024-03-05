struct SourceCodeLocation {
  var filePath: String
  var fileName: String
  var line: UInt
}

#if canImport(ObjectiveC)
import XCTest

extension SourceCodeLocation {
  init(_ location: XCTSourceCodeLocation) {
    self.filePath = location.fileURL.path
    self.fileName = location.fileURL.lastPathComponent
    self.line = UInt(location.lineNumber)
  }
}
#endif
