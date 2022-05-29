@testable import Core
import XCTest

final class CollectorTests: XCTestCase {
  func testDefaultCollector() throws {
    let environment = EnvironmentValues(values: [:])
    let collector = Collector(environment: environment)
    let observer = try XCTUnwrap(collector.observer, "Observer should be initialised")
    XCTAssertNil(observer.uploader, "Uploader should not be initialised without an api key")
  }

  func testDefaultCollectorWithUploader() throws {
    let environment = EnvironmentValues(values: ["BUILDKITE_ANALYTICS_TOKEN": "SECRET"])
    let collector = Collector(environment: environment)
    let observer = try XCTUnwrap(collector.observer, "Observer should be created by default")
    XCTAssertNotNil(observer.uploader, "Uploader should be initialised when provided an api key")
  }

  func testCollectorIsDisabled() {
    let environment = EnvironmentValues(values: ["BUILDKITE_ANALYTICS_ENABLED": "False"])
    let collector = Collector(environment: environment)
    XCTAssertNil(collector.observer)
  }
}
