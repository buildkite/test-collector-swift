@testable import Core
import OpenTelemetryApi
import OpenTelemetrySdk
import XCTest

final class SynchronousExecutionSpanProcessorTests: XCTestCase {
  func testBacksOffFailedExportsAndResetsAfterSuccess() {
    let clock = TestClock()
    let exporter = SequencedExporter(results: [
      .failure, .failure, .failure, .failure, .failure, .success, .success,
    ])
    let processor = SynchronousExecutionSpanProcessor(
      exporter: exporter,
      logger: nil,
      now: { clock.now }
    )
    let tracer = TracerProviderSdk(spanProcessors: [processor]).get(
      instrumentationName: "SynchronousExecutionSpanProcessorTests"
    )

    self.endSpan("one", with: tracer)
    self.endSpan("two", with: tracer)
    clock.now = 9
    self.endSpan("three", with: tracer)
    XCTAssertEqual(exporter.exports.count, 1)

    clock.now = 10
    self.endSpan("four", with: tracer)
    clock.now = 29
    self.endSpan("five", with: tracer)
    XCTAssertEqual(exporter.exports.count, 2)

    clock.now = 30
    self.endSpan("six", with: tracer)
    clock.now = 59
    self.endSpan("seven", with: tracer)
    XCTAssertEqual(exporter.exports.count, 3)

    clock.now = 60
    self.endSpan("eight", with: tracer)
    clock.now = 119
    self.endSpan("nine", with: tracer)
    XCTAssertEqual(exporter.exports.count, 4)

    clock.now = 120
    self.endSpan("ten", with: tracer)
    clock.now = 179
    self.endSpan("eleven", with: tracer)
    XCTAssertEqual(exporter.exports.count, 5)

    clock.now = 180
    self.endSpan("twelve", with: tracer)
    self.endSpan("thirteen", with: tracer)

    XCTAssertEqual(exporter.exports.count, 7)
    XCTAssertEqual(exporter.exports.map(\.count), [1, 4, 6, 8, 10, 12, 1])
  }

  private func endSpan(_ name: String, with tracer: any Tracer) {
    tracer.spanBuilder(spanName: name).setNoParent().startSpan().end()
  }
}

private final class TestClock {
  var now: TimeInterval = 0
}

private final class SequencedExporter: SpanExporter, @unchecked Sendable {
  private var results: [SpanExporterResultCode]
  var exports = [[SpanData]]()

  init(results: [SpanExporterResultCode]) {
    self.results = results
  }

  func export(spans: [SpanData], explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
    self.exports.append(spans)
    return self.results.removeFirst()
  }

  func flush(explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
    .success
  }

  func shutdown(explicitTimeout: TimeInterval?) {}
}
