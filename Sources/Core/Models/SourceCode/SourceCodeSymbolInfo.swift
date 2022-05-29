struct SourceCodeSymbolInfo {
  var imageName: String
  var location: SourceCodeLocation?
  var symbolName: String
}

#if canImport(ObjectiveC)
import XCTest

extension SourceCodeSymbolInfo {
  init(_ info: XCTSourceCodeSymbolInfo) {
    self.imageName = info.imageName
    self.location = info.location.map(SourceCodeLocation.init)
    self.symbolName = info.symbolName
  }
}
#endif
