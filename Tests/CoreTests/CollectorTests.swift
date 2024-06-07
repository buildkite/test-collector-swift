@testable import Core
import XCTest

final class CollectorTests: XCTestCase {
  func testDefaultCollector() throws {
    let environment = EnvironmentValues(values: [:])
    let collector = TestCollector(environment: environment)
    let observer = try XCTUnwrap(collector.observer, "Observer should be initialised")
    XCTAssertNotNil(observer.uploader, "Uploader should be initialised without an api key")
  }

  func testDefaultCollectorWithUploader() throws {
    let environment = EnvironmentValues(values: ["BUILDKITE_ANALYTICS_TOKEN": "SECRET"])
    let collector = TestCollector(environment: environment)
    let observer = try XCTUnwrap(collector.observer, "Observer should be created by default")
    XCTAssertNotNil(observer.uploader, "Uploader should be initialised when provided an api key")
  }

  func testCollectorWithoutCachingEnabledAndWithoutAPIKey() throws {
    let environment = EnvironmentValues(values: ["BUILDKITE_ANALYTICS_CACHING_ENABLED": "false"])
    let collector = TestCollector(environment: environment)
    let observer = try XCTUnwrap(collector.observer, "Observer should be created by default")
    XCTAssertNil(observer.uploader, "Uploader should not be initialised when cache is disabled and api key is not provided")
  }

  func testCollectorIsDisabled() {
    let environment = EnvironmentValues(values: ["BUILDKITE_ANALYTICS_ENABLED": "False"])
    let collector = TestCollector(environment: environment)
    XCTAssertNil(collector.observer)
  }
}
