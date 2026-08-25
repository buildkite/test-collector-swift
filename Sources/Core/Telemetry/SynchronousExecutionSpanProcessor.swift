import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk

final class SynchronousExecutionSpanProcessor: SpanProcessor {
  private static let retryDelays: [TimeInterval] = [10, 20, 30, 60]

  let isStartRequired = false
  let isEndRequired = true

  private let exporter: any SpanExporter
  private let exporterLock = NSLock()
  private let logger: Logger?
  private let now: () -> TimeInterval
  private var pending = [SpanData]()
  private var retryDelayIndex = 0
  private var retryNotBefore: TimeInterval?

  init(
    exporter: any SpanExporter,
    logger: Logger?,
    now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
  ) {
    self.exporter = exporter
    self.logger = logger
    self.now = now
  }

  func onStart(parentContext: SpanContext?, span: any ReadableSpan) {}

  func onEnd(span: any ReadableSpan) {
    self.exporterLock.lock()
    defer { self.exporterLock.unlock() }

    let name = span.getAttributes()[BuildkiteTelemetryAttribute.testName]?.description ?? span.name
    self.pending.append(span.toSpanData())
    if let retryNotBefore = self.retryNotBefore, self.now() < retryNotBefore {
      self.logger?.debug(
        "Queued OpenTelemetry test execution during export backoff: \(name) (\(self.pending.count) pending)"
      )
      return
    }

    if self.exportPending() {
      self.logger?.debug("Exported OpenTelemetry test execution: \(name)")
    } else {
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
    if !self.pending.isEmpty, !self.exportPending(timeout: timeout) {
      self.logger?.error("OpenTelemetry export failed while retrying pending test executions")
    }
    if case .failure = self.exporter.flush(explicitTimeout: timeout) {
      self.logger?.error("OpenTelemetry export failed while flushing pending test executions")
    }
  }

  private func exportPending(timeout: TimeInterval? = nil) -> Bool {
    switch self.exporter.export(spans: self.pending, explicitTimeout: timeout) {
    case .success:
      self.pending.removeAll()
      self.retryDelayIndex = 0
      self.retryNotBefore = nil
      return true
    case .failure:
      let delay = Self.retryDelays[self.retryDelayIndex]
      self.retryNotBefore = self.now() + delay
      self.retryDelayIndex = min(self.retryDelayIndex + 1, Self.retryDelays.count - 1)
      return false
    }
  }
}
