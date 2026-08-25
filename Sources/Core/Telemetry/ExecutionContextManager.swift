import Foundation
import OpenTelemetryApi

/// Preserves OpenTelemetry's closure-scoped context while allowing XCTest's
/// separate start and finish callbacks to keep an execution span active. It
/// also observes span creation so providers registered during a test can be
/// configured before their first child span starts.
final class ExecutionContextManager: ContextManager {
  private final class ThreadSuppression: NSObject {
    var counts = [String: Int]()
  }

  @TaskLocal private static var suppressedKeys = Set<String>()

  private let contextReadHandler = LockIsolated<(() -> Void)?>(nil)
  private let delegate: OpenTelemetryContextProvider
  private let executionSpan = LockIsolated<(any Span)?>(nil)
  private let threadSuppressionKey = "com.buildkite.test-collector-swift.otel-context-suppression"

  init(delegate: OpenTelemetryContextProvider) {
    self.delegate = delegate
  }

  func getCurrentContextValue(forKey key: OpenTelemetryContextKeys) -> AnyObject? {
    if key == .span {
      let handler = self.contextReadHandler.withValue { $0 }
      handler?()
    }
    guard !self.isSuppressed(key) else { return nil }

    switch key {
    case .span:
      return self.delegate.activeSpan ?? self.executionSpan.withValue { $0 }
    case .baggage:
      return self.delegate.activeBaggage
    }
  }

  func setCurrentContextValue(forKey key: OpenTelemetryContextKeys, value: AnyObject) {
    switch key {
    case .span:
      if let span = value as? any Span {
        self.delegate.setActiveSpan(span)
      }
    case .baggage:
      if let baggage = value as? any Baggage {
        self.delegate.setActiveBaggage(baggage)
      }
    }
  }

  func removeContextValue(forKey key: OpenTelemetryContextKeys, value: AnyObject) {
    switch key {
    case .span:
      if let span = value as? any Span {
        self.delegate.removeContextForSpan(span)
      }
    case .baggage:
      if let baggage = value as? any Baggage {
        self.delegate.removeContextForBaggage(baggage)
      }
    }
  }

  func withCurrentContextValue<T>(
    forKey key: OpenTelemetryContextKeys,
    value: AnyObject?,
    _ operation: () throws -> T
  ) rethrows -> T {
    switch (key, value) {
    case let (.span, span as any SpanBase):
      return try self.delegate.withActiveSpan(span, operation)
    case let (.baggage, baggage as any Baggage):
      return try self.delegate.withActiveBaggage(baggage, operation)
    case (_, nil):
      return try self.withSuppressedContext(forKey: key, operation)
    default:
      return try operation()
    }
  }

  func withCurrentContextValue<T>(
    forKey key: OpenTelemetryContextKeys,
    value: AnyObject?,
    _ operation: () async throws -> T
  ) async rethrows -> T {
    switch (key, value) {
    case let (.span, span as any SpanBase):
      return try await self.delegate.withActiveSpan(span, operation)
    case let (.baggage, baggage as any Baggage):
      return try await self.delegate.withActiveBaggage(baggage, operation)
    case (_, nil):
      var keys = Self.suppressedKeys
      keys.insert(key.rawValue)
      return try await Self.$suppressedKeys.withValue(keys, operation: operation)
    default:
      return try await operation()
    }
  }

  func setExecutionSpan(_ span: any Span) {
    self.executionSpan.withValue { $0 = span }
    self.delegate.setActiveSpan(span)
  }

  func removeExecutionSpan(_ span: any Span) {
    self.delegate.removeContextForSpan(span)
    self.executionSpan.withValue { current in
      if current === span {
        current = nil
      }
    }
  }

  func setContextReadHandler(_ handler: @escaping () -> Void) {
    self.contextReadHandler.withValue { $0 = handler }
  }

  private func isSuppressed(_ key: OpenTelemetryContextKeys) -> Bool {
    if Self.suppressedKeys.contains(key.rawValue) {
      return true
    }
    return (self.threadSuppression(create: false)?.counts[key.rawValue] ?? 0) > 0
  }

  private func withSuppressedContext<T>(
    forKey key: OpenTelemetryContextKeys,
    _ operation: () throws -> T
  ) rethrows -> T {
    let suppression = self.threadSuppression(create: true)!
    suppression.counts[key.rawValue, default: 0] += 1
    defer {
      suppression.counts[key.rawValue, default: 0] -= 1
    }
    return try operation()
  }

  private func threadSuppression(create: Bool) -> ThreadSuppression? {
    let dictionary = Thread.current.threadDictionary
    if let suppression = dictionary[self.threadSuppressionKey] as? ThreadSuppression {
      return suppression
    }
    guard create else { return nil }

    let suppression = ThreadSuppression()
    dictionary[self.threadSuppressionKey] = suppression
    return suppression
  }
}
