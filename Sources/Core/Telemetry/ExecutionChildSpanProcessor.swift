import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk

final class ExecutionTraceRegistry {
  private let traceIDs = LockIsolated(Set<TraceId>())

  func insert(_ traceID: TraceId) {
    _ = self.traceIDs.withValue { $0.insert(traceID) }
  }

  func remove(_ traceID: TraceId) {
    _ = self.traceIDs.withValue { $0.remove(traceID) }
  }

  func contains(_ traceID: TraceId) -> Bool {
    self.traceIDs.withValue { $0.contains(traceID) }
  }
}

final class ExecutionChildSpanProcessor: SpanProcessor {
  let isStartRequired = true
  let isEndRequired = true

  private let registry: ExecutionTraceRegistry
  private let state: LockIsolated<State>

  private struct State {
    var active = true
    var acceptedSpanIDs = Set<SpanId>()
    var processor: any SpanProcessor
  }

  init(processor: any SpanProcessor, registry: ExecutionTraceRegistry) {
    self.registry = registry
    self.state = LockIsolated(State(processor: processor))
  }

  func onStart(parentContext: SpanContext?, span: any ReadableSpan) {
    guard
      let parentContext,
      parentContext.traceId == span.context.traceId,
      self.registry.contains(span.context.traceId)
    else { return }

    self.state.withValue { state in
      if state.active {
        state.acceptedSpanIDs.insert(span.context.spanId)
      }
    }
  }

  func onEnd(span: any ReadableSpan) {
    self.state.withValue { state in
      guard state.active, state.acceptedSpanIDs.remove(span.context.spanId) != nil else { return }
      state.processor.onEnd(span: span)
    }
  }

  func forceFlush(timeout: TimeInterval?) {
    self.state.withValue { state in
      if state.active {
        state.processor.forceFlush(timeout: timeout)
      }
    }
  }

  func shutdown(explicitTimeout: TimeInterval?) {
    self.state.withValue { state in
      state.active = false
      state.acceptedSpanIDs.removeAll()
      state.processor.shutdown(explicitTimeout: explicitTimeout)
    }
  }
}
