import Foundation

@dynamicMemberLookup
final class LockIsolated<Value>: @unchecked Sendable {
  private var _value: Value
  private let lock = NSRecursiveLock()

  init(_ value: Value) {
    self._value = value
  }

  var value: Value {
    self.withValue { $0 }
  }

  subscript<Subject: Sendable>(dynamicMember keyPath: KeyPath<Value, Subject>) -> Subject {
    self.withValue { $0[keyPath: keyPath] }
  }

  func withValue<T: Sendable>(_ operation: (inout Value) throws -> T) rethrows -> T {
    self.lock.lock()
    defer { self.lock.unlock() }
    return try operation(&self._value)
  }

  func setValue(_ newValue: Value) {
    self.withValue { $0 = newValue }
  }
}
