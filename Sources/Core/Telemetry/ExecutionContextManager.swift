import Foundation
import OpenTelemetryApi

#if !canImport(os.activity)
/// Preserves OpenTelemetry's closure-scoped context while allowing XCTest's
/// separate start and finish callbacks to keep an execution span active.
final class ExecutionContextManager: ContextManager {
  static let shared = ExecutionContextManager()

  private final class EmptyValue: NSObject {}

  private final class ThreadContext: NSObject {
    var values = [String: [AnyObject]]()
  }

  private static let emptyValue = EmptyValue()
  @TaskLocal private static var taskValues = [String: AnyObject]()

  private let executionSpan = LockIsolated<(any Span)?>(nil)
  private let threadContextKey = "com.buildkite.test-collector-swift.otel-context"

  private init() {}

  func getCurrentContextValue(forKey key: OpenTelemetryContextKeys) -> AnyObject? {
    if let value = self.threadContext(create: false)?.values[key.rawValue]?.last {
      return value === Self.emptyValue ? nil : value
    }
    if let value = Self.taskValues[key.rawValue] {
      return value === Self.emptyValue ? nil : value
    }
    if key == .span {
      return self.executionSpan.withValue { $0 }
    }
    return nil
  }

  func setCurrentContextValue(forKey key: OpenTelemetryContextKeys, value: AnyObject) {
    self.threadContext(create: true)?.values[key.rawValue, default: []].append(value)
  }

  func removeContextValue(forKey key: OpenTelemetryContextKeys, value: AnyObject) {
    guard let context = self.threadContext(create: false),
          var values = context.values[key.rawValue],
          let index = values.lastIndex(where: { $0 === value })
    else { return }

    values.remove(at: index)
    context.values[key.rawValue] = values.isEmpty ? nil : values
  }

  func withCurrentContextValue<T>(
    forKey key: OpenTelemetryContextKeys,
    value: AnyObject?,
    _ operation: () throws -> T
  ) rethrows -> T {
    let scopedValue = value ?? Self.emptyValue
    self.setCurrentContextValue(forKey: key, value: scopedValue)
    defer { self.removeContextValue(forKey: key, value: scopedValue) }
    return try operation()
  }

  func withCurrentContextValue<T>(
    forKey key: OpenTelemetryContextKeys,
    value: AnyObject?,
    _ operation: () async throws -> T
  ) async rethrows -> T {
    var values = Self.taskValues
    values[key.rawValue] = value ?? Self.emptyValue
    return try await Self.$taskValues.withValue(values, operation: operation)
  }

  func setExecutionSpan(_ span: any Span) {
    self.executionSpan.withValue { $0 = span }
  }

  func removeExecutionSpan(_ span: any Span) {
    self.executionSpan.withValue { current in
      if current === span {
        current = nil
      }
    }
  }

  private func threadContext(create: Bool) -> ThreadContext? {
    let dictionary = Thread.current.threadDictionary
    if let context = dictionary[self.threadContextKey] as? ThreadContext {
      return context
    }
    guard create else { return nil }

    let context = ThreadContext()
    dictionary[self.threadContextKey] = context
    return context
  }
}
#endif
