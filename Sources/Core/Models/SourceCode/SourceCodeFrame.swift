struct SourceCodeFrame {
  var address: UInt64
  var symbolInfo: SourceCodeSymbolInfo?
  var symbolicationError: Error?
}

extension SourceCodeFrame: CustomStringConvertible {
  var description: String {
    if let name = self.symbolInfo?.symbolName {
      return name
    } else if let error = self.symbolicationError {
      return error.localizedDescription
    } else {
      return "\(self.address) <unknown>"
    }
  }
}

#if canImport(ObjectiveC)
import XCTest

extension SourceCodeFrame {
  init(_ frame: XCTSourceCodeFrame) {
    self.address = frame.address
    self.symbolInfo = frame.symbolInfo.map(SourceCodeSymbolInfo.init)
    self.symbolicationError = frame.symbolicationError
  }
}
#endif
