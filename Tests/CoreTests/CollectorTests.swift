@testable import Core
import XCTest

final class CollectorTests: XCTestCase {
  func testDefaultCollector() throws {
    let environment = EnvironmentValues(
      values: [:],
      getFromEnvironment: { _ in nil },
      getFromInfoDictionary: { _ in nil }
    )
    let collector = TestCollector(environment: environment)
    let observer = try XCTUnwrap(collector.observer, "Observer should be initialised")
    XCTAssertNil(observer.telemetry, "Telemetry should not be initialised without export configuration")
  }

  func testDefaultCollectorWithTelemetry() throws {
    let environment = EnvironmentValues(values: ["BUILDKITE_ANALYTICS_TOKEN": "SECRET"])
    let collector = TestCollector(environment: environment)
    let observer = try XCTUnwrap(collector.observer, "Observer should be created by default")
    XCTAssertNotNil(observer.telemetry, "Telemetry should be initialised when provided an api key")
  }

  func testCollectorWithOTLPConfigurationDoesNotRequireApiToken() throws {
    let environment = EnvironmentValues(values: [
      "OTEL_EXPORTER_OTLP_TRACES_ENDPOINT": "http://127.0.0.1:4318/v1/traces",
      "OTEL_EXPORTER_OTLP_TRACES_HEADERS": "Authorization=Bearer%20relay-token",
    ])
    let collector = TestCollector(environment: environment)
    let observer = try XCTUnwrap(collector.observer, "Observer should be created by default")
    XCTAssertNotNil(observer.telemetry)
  }

  func testCollectorIsDisabled() {
    let environment = EnvironmentValues(values: ["BUILDKITE_ANALYTICS_ENABLED": "False"])
    let collector = TestCollector(environment: environment)
    XCTAssertNil(collector.observer)
  }

  func testWarnsWhenLegacyAnalyticsBaseURLIsIgnored() {
    let messages = LockIsolated([String]())
    let logger = Logger(printer: { message in
      messages.withValue { $0.append(message) }
    })
    let environment = EnvironmentValues(values: [
      "BUILDKITE_ANALYTICS_BASE_URL": "https://example.com/v1/",
    ])

    _ = TestCollector(environment: environment, logger: logger)
    logger.waitForLogs()

    XCTAssertTrue(messages.withValue { messages in
      messages.contains(
        "[BuildkiteTestCollector] warning: BUILDKITE_ANALYTICS_BASE_URL is no longer supported and is ignored; use BUILDKITE_ANALYTICS_OTLP_ENDPOINT or OTEL_EXPORTER_OTLP_TRACES_ENDPOINT instead."
      )
    })
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
