@testable import Core
import XCTest

final class CollectorTests: XCTestCase {
  func testDefaultCollector() throws {
    let environment = EnvironmentValues(values: [:])
    let collector = TestCollector(environment: environment)
    let observer = try XCTUnwrap(collector.observer, "Observer should be initialised")
    XCTAssertNil(observer.uploader, "Uploader should not be initialised without an api key")
  }

  func testDefaultCollectorWithUploader() throws {
    let environment = EnvironmentValues(values: ["BUILDKITE_ANALYTICS_TOKEN": "SECRET"])
    let collector = TestCollector(environment: environment)
    let observer = try XCTUnwrap(collector.observer, "Observer should be created by default")
    XCTAssertNotNil(observer.uploader, "Uploader should be initialised when provided an api key")
  }

  func testCollectorIsDisabled() {
    let environment = EnvironmentValues(values: ["BUILDKITE_ANALYTICS_ENABLED": "False"])
    let collector = TestCollector(environment: environment)
    XCTAssertNil(collector.observer)
  }

  func testUploadTagsEnvVarTakesPrecedence() {
    let environment = EnvironmentValues(values: [
      "BUILDKITE_ANALYTICS_TAGS": #"{"shared":"from-env","env-only":"yes"}"#,
    ])
    let envTags = environment.analyticsTags ?? [:]
    let programmatic = ["shared": "from-code", "code-only": "yes"]
    let merged = programmatic.merging(envTags) { _, env in env }
    XCTAssertEqual(merged["shared"], "from-env")
    XCTAssertEqual(merged["code-only"], "yes")
    XCTAssertEqual(merged["env-only"], "yes")
  }
}
