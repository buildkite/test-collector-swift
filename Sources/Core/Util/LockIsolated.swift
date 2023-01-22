import Foundation

@dynamicMemberLookup
final class LockIsolated<Value>: @unchecked Sendable {
  private var _value: Value
  private let lock = NSRecursiveLock()

  init(_ value: Value) {
    self._value = value
  }

  var value: Value {
    _read {
      self.lock.lock()
      defer { self.lock.unlock() }
      yield self._value
    }
    _modify {
      self.lock.lock()
      defer { self.lock.unlock() }
      yield &self._value
    }
  }

  subscript<Subject: Sendable>(dynamicMember keyPath: KeyPath<Value, Subject>) -> Subject {
    _read { yield self.value[keyPath: keyPath] }
  }

  subscript<Subject: Sendable>(dynamicMember keyPath: WritableKeyPath<Value, Subject>) -> Subject {
    _read { yield self._value[keyPath: keyPath] }
    _modify { yield &self._value[keyPath: keyPath] }
  }
}

extension LockIsolated: Equatable where Value: Equatable {
  static func == (lhs: LockIsolated, rhs: LockIsolated) -> Bool {
    lhs.value == rhs.value
  }
}
