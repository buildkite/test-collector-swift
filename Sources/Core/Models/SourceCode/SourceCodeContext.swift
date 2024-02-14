struct SourceCodeContext {
  var callStack: [SourceCodeFrame] = []
  var location: SourceCodeLocation?
}

extension SourceCodeContext {
  init(filePath: String, line: Int, callStack: [SourceCodeFrame] = []) {
    self.callStack = callStack
    self.location = .init(filePath: filePath, line: UInt(line))
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
