struct TestIssue {
  var compactDescription: String
  var description: String
  var sourceCodeContext: SourceCodeContext
  var associatedError: Error?
}

extension TestIssue {
  init(_ description: String, context: SourceCodeContext) {
    self.compactDescription = description
    self.description = description
    self.sourceCodeContext = context
  }
}

#if canImport(ObjectiveC)
import XCTest

extension TestIssue {
  init(_ issue: XCTIssue) {
    self.compactDescription = issue.compactDescription
    self.description = issue.description
    self.sourceCodeContext = .init(issue.sourceCodeContext)
    self.associatedError = issue.associatedError
  }
}
#endif
