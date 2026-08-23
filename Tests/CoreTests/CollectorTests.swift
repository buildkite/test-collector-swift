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

  func testWorkerIdTagFromAgentIdIsMergedWithLowestPrecedence() {
    let environment = EnvironmentValues(values: [
      "BUILDKITE_AGENT_ID": "agent-123",
      "BUILDKITE_ANALYTICS_TAGS": #"{"ci.worker.id":"from-env"}"#,
    ])
    let envTags = environment.analyticsTags ?? [:]
    let programmatic = ["ci.worker.id": "from-code"]
    let callerTags = programmatic.merging(envTags) { _, env in env }
    let workerIdTag = environment.buildkiteAgentId.map { ["ci.worker.id": $0] } ?? [:]
    let merged = workerIdTag.merging(callerTags) { _, caller in caller }
    XCTAssertEqual(merged["ci.worker.id"], "from-env")
  }

  func testWorkerIdTagUsedWhenNoCallerTagProvided() {
    let environment = EnvironmentValues(values: ["BUILDKITE_AGENT_ID": "agent-123"])
    let workerIdTag = environment.buildkiteAgentId.map { ["ci.worker.id": $0] } ?? [:]
    let merged = workerIdTag.merging([String: String]()) { _, caller in caller }
    XCTAssertEqual(merged["ci.worker.id"], "agent-123")
  }

  func testWorkerIdTagOmittedWhenAgentIdMissing() {
    let environment = EnvironmentValues(values: [:])
    XCTAssertNil(environment.buildkiteAgentId)
  }
}
