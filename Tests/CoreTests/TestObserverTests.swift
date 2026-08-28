@testable import Core
import XCTest

final class TestObserverTests: XCTestCase {
  func testExecutionTagsFlowToTelemetry() {
    let recordedTags = LockIsolated([[String: String]?]())
    let telemetry = self.telemetry { tags in recordedTags.withValue { $0.append(tags) } }
    let observer = TestObserver(logger: nil, telemetry: telemetry)

    observer.testCaseWillStart(self)
    observer.setTag(for: self, key: "suite", value: "smoke")
    observer.setTag(for: self, key: "feature", value: "payments")
    observer.testCaseDidFinish(self)

    XCTAssertEqual(recordedTags.value.count, 1)
    XCTAssertEqual(recordedTags.value.first!, ["suite": "smoke", "feature": "payments"])
  }

  func testExecutionTagsNilWhenEmpty() {
    let recordedTags = LockIsolated([[String: String]?]())
    let telemetry = self.telemetry { tags in recordedTags.withValue { $0.append(tags) } }
    let observer = TestObserver(logger: nil, telemetry: telemetry)

    observer.testCaseWillStart(self)
    observer.testCaseDidFinish(self)

    XCTAssertEqual(recordedTags.value.count, 1)
    XCTAssertNil(recordedTags.value.first!)
  }

  func testLateTagIsIgnored() {
    let recordedTags = LockIsolated([[String: String]?]())
    let telemetry = self.telemetry { tags in recordedTags.withValue { $0.append(tags) } }
    let observer = TestObserver(logger: nil, telemetry: telemetry)

    observer.testCaseWillStart(self)
    observer.setTag(for: self, key: "before", value: "yes")
    observer.testCaseDidFinish(self)

    // Tag set after finish should be ignored
    observer.setTag(for: self, key: "after", value: "should-not-appear")

    XCTAssertEqual(recordedTags.value.count, 1)
    XCTAssertEqual(recordedTags.value.first!, ["before": "yes"])
  }

  private func telemetry(onFinish: @escaping ([String: String]?) -> Void) -> TelemetryClient {
    TelemetryClient(
      start: { $0.id },
      annotate: { _, _ in },
      finish: { _, _, tags in onFinish(tags) },
      flush: {}
    )
  }
}
