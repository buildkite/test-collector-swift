import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk

final class SynchronousExecutionSpanProcessor: SpanProcessor {
  let isStartRequired = false
  let isEndRequired = true

  private let exporter: any SpanExporter
  private let exporterLock = NSLock()
  private let logger: Logger?

  init(exporter: any SpanExporter, logger: Logger?) {
    self.exporter = exporter
    self.logger = logger
  }

  func onStart(parentContext: SpanContext?, span: any ReadableSpan) {}

  func onEnd(span: any ReadableSpan) {
    self.exporterLock.lock()
    defer { self.exporterLock.unlock() }

    let name = span.getAttributes()[BuildkiteTelemetryAttribute.testName]?.description ?? span.name
    switch self.exporter.export(spans: [span.toSpanData()]) {
    case .success:
      self.logger?.debug("Exported OpenTelemetry test execution: \(name)")
    case .failure:
      self.logger?.error(
        "OpenTelemetry export failed for \(name); the execution remains queued in this process"
      )
    }
  }

  func forceFlush(timeout: TimeInterval?) {
    self.exporterLock.lock()
    defer { self.exporterLock.unlock() }
    self.flush(timeout: timeout)
  }

  func shutdown(explicitTimeout: TimeInterval?) {
    self.exporterLock.lock()
    defer { self.exporterLock.unlock() }
    self.flush(timeout: explicitTimeout)
    self.exporter.shutdown(explicitTimeout: explicitTimeout)
  }

  private func flush(timeout: TimeInterval?) {
    if case .failure = self.exporter.flush(explicitTimeout: timeout) {
      self.logger?.error("OpenTelemetry export failed while flushing pending test executions")
    }
  }
}
