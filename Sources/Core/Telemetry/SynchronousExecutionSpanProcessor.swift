import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk

final class SynchronousExecutionSpanProcessor: SpanProcessor {
  let isStartRequired = false
  let isEndRequired = true

  private let exporter: any SpanExporter
  private let exporterLock = NSLock()
  private let logger: Logger?
  private var pending = [SpanData]()

  init(exporter: any SpanExporter, logger: Logger?) {
    self.exporter = exporter
    self.logger = logger
  }

  func onStart(parentContext: SpanContext?, span: any ReadableSpan) {}

  func onEnd(span: any ReadableSpan) {
    self.exporterLock.lock()
    defer { self.exporterLock.unlock() }

    let name = span.getAttributes()[BuildkiteTelemetryAttribute.testName]?.description ?? span.name
    self.pending.append(span.toSpanData())
    switch self.exporter.export(spans: self.pending) {
    case .success:
      self.pending.removeAll()
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
    if !self.pending.isEmpty {
      switch self.exporter.export(spans: self.pending, explicitTimeout: timeout) {
      case .success:
        self.pending.removeAll()
      case .failure:
        self.logger?.error("OpenTelemetry export failed while retrying pending test executions")
      }
    }
    if case .failure = self.exporter.flush(explicitTimeout: timeout) {
      self.logger?.error("OpenTelemetry export failed while flushing pending test executions")
    }
  }
}
