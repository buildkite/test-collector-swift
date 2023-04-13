/// Returns a Boolean value indicating whether two values are equal.
///
/// - Parameters:
///   - lhs: A value to compare.
///   - rhs: Another value to compare.
func isEqual(_ lhs: Any, _ rhs: Any) -> Bool {
  func open<T>(_: T.Type) -> ((Any, Any) -> Bool)? {
    (Witness<T>.self as? AnyEquatable.Type)?.isEqual
  }

  if let isEqual = _openExistential(type(of: lhs), do: open) {
    // lhs is equatable
    return isEqual(lhs, rhs)
  } else if
    let lhs = lhs as? [Any],
    let rhs = rhs as? [Any]
  {
    // Arrays that are not equatable or have been type-erased
    return lhs.elementsEqual(rhs, by: isEqual)
  } else if
    let lhs = lhs as? [AnyHashable: Any],
    let rhs = rhs as? [AnyHashable: Any],
    lhs.count == rhs.count
  {
    // Dictionaries that are not equatable or have been type-erased
    return lhs.allSatisfy { isEqual($1, rhs[$0] as Any) }
  } else {
    return false
  }
}

private enum Witness<T> {}

private protocol AnyEquatable {
  static func isEqual(_ lhs: Any, _ rhs: Any) -> Bool
}

extension Witness: AnyEquatable where T: Equatable {
  fileprivate static func isEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    lhs as? T == rhs as? T
  }
}
