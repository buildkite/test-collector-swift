import XCTest

extension XCTestObservationCenter {
  var observers: [XCTestObservation] {
    #if canImport(ObjectiveC)
    return self.value(forKey: "_observers") as! [XCTestObservation]
    #else
    let wrappedObservers = Mirror(reflecting: self).descendant("observers") as! Set<AnyHashable>
    return wrappedObservers
      .map { Mirror(reflecting: $0.base).descendant("object") as! XCTestObservation }
    #endif
  }
}
