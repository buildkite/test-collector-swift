@testable import Core
import XCTest

final class TestObserverTests: XCTestCase {
  func testExecutionTagsFlowToTrace() {
    let recordedTraces = LockIsolated([Trace]())
    let uploader = UploadClient(
      record: { trace in recordedTraces.withValue { $0.append(trace) } },
      waitForUploads: { _ in }
    )
    let tracer = Tracer(
      startSpan: { section, _ in section as AnyHashable },
      endSpan: { id in Trace.Span(section: id as! String) }
    )
    let observer = TestObserver(logger: nil, tracer: tracer, uploader: uploader)

    observer.testCaseWillStart(self)
    observer.setTag(for: self, key: "suite", value: "smoke")
    observer.setTag(for: self, key: "feature", value: "payments")
    observer.testCaseDidFinish(self)

    XCTAssertEqual(recordedTraces.value.count, 1)
    XCTAssertEqual(recordedTraces.value.first?.tags, ["suite": "smoke", "feature": "payments"])
  }

  func testExecutionTagsNilWhenEmpty() {
    let recordedTraces = LockIsolated([Trace]())
    let uploader = UploadClient(
      record: { trace in recordedTraces.withValue { $0.append(trace) } },
      waitForUploads: { _ in }
    )
    let tracer = Tracer(
      startSpan: { section, _ in section as AnyHashable },
      endSpan: { id in Trace.Span(section: id as! String) }
    )
    let observer = TestObserver(logger: nil, tracer: tracer, uploader: uploader)

    observer.testCaseWillStart(self)
    observer.testCaseDidFinish(self)

    XCTAssertEqual(recordedTraces.value.count, 1)
    XCTAssertNil(recordedTraces.value.first?.tags)
  }

  func testLateTagIsIgnored() {
    let recordedTraces = LockIsolated([Trace]())
    let uploader = UploadClient(
      record: { trace in recordedTraces.withValue { $0.append(trace) } },
      waitForUploads: { _ in }
    )
    let tracer = Tracer(
      startSpan: { section, _ in section as AnyHashable },
      endSpan: { id in Trace.Span(section: id as! String) }
    )
    let observer = TestObserver(logger: nil, tracer: tracer, uploader: uploader)

    observer.testCaseWillStart(self)
    observer.setTag(for: self, key: "before", value: "yes")
    observer.testCaseDidFinish(self)

    // Tag set after finish should be ignored
    observer.setTag(for: self, key: "after", value: "should-not-appear")

    XCTAssertEqual(recordedTraces.value.count, 1)
    XCTAssertEqual(recordedTraces.value.first?.tags, ["before": "yes"])
  }
}
