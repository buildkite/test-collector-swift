struct SourceCodeContext {
  var callStack: [SourceCodeFrame] = []
  var location: SourceCodeLocation?
}

extension SourceCodeContext {
  init(fileURL: URL, line: Int, callStack: [SourceCodeFrame] = []) {
    self.callStack = callStack
    self.location = .init(fileURL: fileURL, line: UInt(line))
  }
}

#if canImport(ObjectiveC)
import XCTest

extension SourceCodeContext {
  init(_ context: XCTSourceCodeContext) {
    self.callStack = context.callStack.map(SourceCodeFrame.init)
    self.location = context.location.map(SourceCodeLocation.init)
  }
}
#endif
