import XCTest

final class BuildkiteCollectorTests: XCTestCase {
  // NB: The BuildkiteCollector module should not be imported above
  func testAutomaticallyConfiguresCollectorBeforeRunningTests() throws {
    let observers = XCTestObservationCenter.shared.observers
    XCTAssertTrue(
      observers.contains(where: { String(reflecting: type(of: $0)) == "Core.TestObserver" }),
      "Observer should be automatically added to the observation center"
    )
  }
}
