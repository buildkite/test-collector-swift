@testable import Core
import InMemoryExporter
import OpenTelemetryApi
import OpenTelemetrySdk
import XCTest

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

final class TelemetryClientTests: XCTestCase {
  override func setUp() {
    super.setUp()
    OpenTelemetry.registerTracerProvider(tracerProvider: DefaultTracerProvider.instance)
  }

  override func tearDown() {
    OpenTelemetry.registerTracerProvider(tracerProvider: DefaultTracerProvider.instance)
    super.tearDown()
  }

  func testExportsExecutionRootSynchronouslyWithAttributesAndRunTags() throws {
    let rootExporter = InMemoryExporter()
    let childExporter = InMemoryExporter()
    let environment = EnvironmentValues(
      values: [
        "BUILDKITE_ANALYTICS_TOKEN": "SECRET",
        "BUILDKITE_ANALYTICS_KEY": "run-key",
        "BUILDKITE_AGENT_ID": "agent-id",
        "BUILDKITE_BUILD_ID": "build-id",
        "BUILDKITE_BUILD_NUMBER": "123",
        "BUILDKITE_BUILD_URL": "https://buildkite.example/builds/123",
        "BUILDKITE_BRANCH": "main",
        "BUILDKITE_COMMIT": "abc123",
        "BUILDKITE_JOB_ID": "job-id",
        "BUILDKITE_MESSAGE": "Test resource boundaries",
        "BUILDKITE_ORGANIZATION_SLUG": "acme",
        "BUILDKITE_STEP_ID": "step-id",
        "BUILDKITE_TEST_ENGINE_SUITE_SLUG": "swift-suite",
      ],
      getFromEnvironment: { _ in nil },
      getFromInfoDictionary: { _ in nil }
    )
    let client = try XCTUnwrap(TelemetryClient.live(
      environment: environment,
      uploadTags: ["feature": "configured", "language": "swift"],
      logger: nil,
      rootExporter: rootExporter,
      childExporter: childExporter
    ))
    var test = TestState(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
      className: "PaymentTests",
      testName: "testChargeCard"
    )

    let executionID = client.startExecution(test)
    let child = OpenTelemetry.instance.tracerProvider
      .get(instrumentationName: "example-app")
      .spanBuilder(spanName: "database.query")
      .startSpan()
    child.end()
    client.annotate("checkpoint", executionID: executionID)
    test.result = .passed
    client.finishExecution(executionID, test: test, tags: ["feature": "payments"])
    client.forceFlush()

    let span = try XCTUnwrap(rootExporter.getFinishedSpanItems().only)
    let exportedChild = try XCTUnwrap(childExporter.getFinishedSpanItems().only)
    XCTAssertEqual(span.name, "test.execution")
    XCTAssertNil(span.parentSpanId)
    XCTAssertEqual(span.attributes[BuildkiteTelemetryAttribute.executionVia], .string("otlp"))
    XCTAssertEqual(span.attributes[BuildkiteTelemetryAttribute.executionScope], .string("PaymentTests"))
    XCTAssertEqual(span.attributes[BuildkiteTelemetryAttribute.testName], .string("testChargeCard"))
    XCTAssertEqual(span.attributes["test.case.result.status"], .string("pass"))
    XCTAssertEqual(span.attributes["buildkite.tag.feature"], .string("payments"))
    XCTAssertEqual(span.attributes["buildkite.tag.language"], .string("swift"))
    XCTAssertEqual(span.attributes[BuildkiteTelemetryAttribute.runKey], .string("run-key"))
    XCTAssertEqual(span.attributes[BuildkiteTelemetryAttribute.buildNumber], .string("123"))
    XCTAssertEqual(span.attributes[BuildkiteTelemetryAttribute.jobID], .string("job-id"))
    XCTAssertEqual(span.attributes[BuildkiteTelemetryAttribute.stepID], .string("step-id"))
    XCTAssertEqual(span.attributes[BuildkiteTelemetryAttribute.message], .string("Test resource boundaries"))
    XCTAssertEqual(span.attributes[BuildkiteTelemetryAttribute.collectorName], .string(TestCollector.name))
    XCTAssertEqual(span.attributes[BuildkiteTelemetryAttribute.collectorVersion], .string(TestCollector.version))
    XCTAssertEqual(span.attributes[BuildkiteTelemetryAttribute.frameworkName], .string("xctest"))
    XCTAssertNil(span.attributes[BuildkiteTelemetryAttribute.runURL])
    XCTAssertEqual(span.resource.attributes["service.name"], .string("swift-suite"))
    XCTAssertEqual(span.resource.attributes["service.namespace"], .string("acme"))
    XCTAssertEqual(span.resource.attributes["cicd.pipeline.run.id"], .string("build-id"))
    XCTAssertEqual(
      span.resource.attributes["cicd.pipeline.run.url.full"],
      .string("https://buildkite.example/builds/123")
    )
    XCTAssertEqual(span.resource.attributes["cicd.worker.id"], .string("agent-id"))
    XCTAssertEqual(span.resource.attributes["vcs.ref.head.name"], .string("main"))
    XCTAssertEqual(span.resource.attributes["vcs.ref.head.revision"], .string("abc123"))
    XCTAssertEqual(span.resource.attributes["vcs.ref.type"], .string("branch"))
    XCTAssertNil(span.resource.attributes["service.instance.id"])
    XCTAssertNil(span.resource.attributes[BuildkiteTelemetryAttribute.runKey])
    XCTAssertNil(span.resource.attributes[BuildkiteTelemetryAttribute.jobID])
    XCTAssertNil(span.resource.attributes[BuildkiteTelemetryAttribute.frameworkName])
    XCTAssertNil(span.resource.attributes["buildkite.tag.language"])
    XCTAssertEqual(exportedChild.traceId, span.traceId)
    XCTAssertEqual(exportedChild.parentSpanId, span.spanId)
    XCTAssertEqual(exportedChild.resource.attributes["service.name"], .string("swift-suite"))
    XCTAssertEqual(exportedChild.resource.attributes["cicd.pipeline.run.id"], .string("build-id"))
    XCTAssertNil(exportedChild.resource.attributes[BuildkiteTelemetryAttribute.runKey])
    XCTAssertNil(exportedChild.resource.attributes[BuildkiteTelemetryAttribute.frameworkName])
    XCTAssertNil(exportedChild.resource.attributes["buildkite.tag.language"])
    XCTAssertEqual(span.events.only?.name, "test.annotation")
    XCTAssertEqual(
      span.events.only?.attributes[BuildkiteTelemetryAttribute.annotation],
      .string("checkpoint")
    )
  }

  func testExportsFailureLocationStatusAndException() throws {
    let rootExporter = InMemoryExporter()
    let client = try XCTUnwrap(TelemetryClient.live(
      environment: self.configuredEnvironment,
      uploadTags: [:],
      logger: nil,
      rootExporter: rootExporter,
      childExporter: InMemoryExporter()
    ))
    var test = TestState(id: UUID(), className: "FailureTests", testName: "testFailure")
    test.result = .failed
    test.issues = [
      TestIssue(
        compactDescription: "Expected true but was false",
        description: "XCTAssertTrue failed",
        sourceCodeContext: SourceCodeContext(
          callStack: [SourceCodeFrame(address: 1, symbolInfo: SourceCodeSymbolInfo(
            imageName: "Tests",
            symbolName: "FailureTests.testFailure()"
          ))],
          location: SourceCodeLocation(
            filePath: "/src/FailureTests.swift",
            fileName: "FailureTests.swift",
            line: 42
          )
        )
      ),
    ]

    let executionID = client.startExecution(test)
    client.finishExecution(executionID, test: test, tags: nil)

    let span = try XCTUnwrap(rootExporter.getFinishedSpanItems().only)
    XCTAssertEqual(span.attributes["test.case.result.status"], .string("fail"))
    XCTAssertEqual(span.attributes["code.file.path"], .string("/src/FailureTests.swift"))
    XCTAssertEqual(span.attributes["code.line.number"], .int(42))
    XCTAssertEqual(span.status, .error(description: "Expected true but was false"))
    XCTAssertEqual(span.events.only?.name, "exception")
    XCTAssertEqual(span.events.only?.attributes["exception.message"], .string("XCTAssertTrue failed"))
    XCTAssertEqual(
      span.events.only?.attributes["exception.stacktrace"],
      .string("0 FailureTests.testFailure()")
    )
  }

  func testExecutionRemainsRootAndLinksToInheritedJobContext() throws {
    let traceParent = "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
    let previousTraceParent = getenv("TRACEPARENT").map { String(cString: $0) }
    setenv("TRACEPARENT", traceParent, 1)
    defer {
      if let previousTraceParent {
        setenv("TRACEPARENT", previousTraceParent, 1)
      } else {
        unsetenv("TRACEPARENT")
      }
    }

    let rootExporter = InMemoryExporter()
    let client = try XCTUnwrap(TelemetryClient.live(
      environment: EnvironmentValues(
        values: [
          "BUILDKITE_ANALYTICS_KEY": "run-key",
          "BUILDKITE_ANALYTICS_TOKEN": "SECRET",
        ],
        getFromInfoDictionary: { _ in nil }
      ),
      uploadTags: [:],
      logger: nil,
      rootExporter: rootExporter,
      childExporter: InMemoryExporter()
    ))
    var test = TestState(id: UUID(), className: "LinkedTests", testName: "testLink")

    let executionID = client.startExecution(test)
    test.result = .passed
    client.finishExecution(executionID, test: test, tags: nil)

    let span = try XCTUnwrap(rootExporter.getFinishedSpanItems().only)
    XCTAssertNil(span.parentSpanId)
    XCTAssertEqual(span.links.only?.context.traceId.hexString, "4bf92f3577b34da6a3ce929d0e0e4736")
    XCTAssertEqual(span.links.only?.context.spanId.hexString, "00f067aa0ba902b7")
  }

  func testExportsSpansFromAProviderRegisteredAfterExecutionStarts() throws {
    let rootExporter = InMemoryExporter()
    let childExporter = InMemoryExporter()
    let client = try XCTUnwrap(TelemetryClient.live(
      environment: self.configuredEnvironment,
      uploadTags: [:],
      logger: nil,
      rootExporter: rootExporter,
      childExporter: childExporter
    ))
    var test = TestState(id: UUID(), className: "ChildTests", testName: "testChild")

    let executionID = client.startExecution(test)
    let replacementProvider = TracerProviderBuilder()
      .with(resource: Resource(attributes: ["service.name": .string("suite-app")]))
      .with(sampler: Samplers.alwaysOn)
      .build()
    OpenTelemetry.registerTracerProvider(tracerProvider: replacementProvider)
    let child = OpenTelemetry.instance.tracerProvider
      .get(instrumentationName: "example-app")
      .spanBuilder(spanName: "database.query")
      .startSpan()
    child.end()
    test.result = .passed
    client.finishExecution(executionID, test: test, tags: nil)
    client.forceFlush()

    let root = try XCTUnwrap(rootExporter.getFinishedSpanItems().only)
    let exportedChild = try XCTUnwrap(childExporter.getFinishedSpanItems().only)
    XCTAssertEqual(exportedChild.traceId, root.traceId)
    XCTAssertEqual(exportedChild.parentSpanId, root.spanId)
    XCTAssertEqual(exportedChild.resource.attributes["service.name"], .string("suite-app"))
    XCTAssertNil(exportedChild.resource.attributes[BuildkiteTelemetryAttribute.runKey])
    XCTAssertNil(exportedChild.resource.attributes[BuildkiteTelemetryAttribute.frameworkName])
  }

  func testUsesOnlyConfiguredHeadersForStandardTraceEndpoint() throws {
    let configuration = try XCTUnwrap(CollectorOTLPConfiguration(
      environment: EnvironmentValues(
        values: [
          "BUILDKITE_ANALYTICS_KEY": "run-key",
          "BUILDKITE_ANALYTICS_TOKEN": "collector-token",
          "OTEL_EXPORTER_OTLP_TRACES_ENDPOINT": "http://127.0.0.1:1234/v1/traces",
          "OTEL_EXPORTER_OTLP_TRACES_HEADERS": "authorization=Bearer%20relay-token,x-test=value%2Fone",
        ],
        getFromEnvironment: { _ in nil },
        getFromInfoDictionary: { _ in nil }
      ),
      logger: nil
    ))

    XCTAssertEqual(configuration.endpoint.absoluteString, "http://127.0.0.1:1234/v1/traces")
    XCTAssertNil(configuration.header(named: "Buildkite-Tests-Run-Key"))
    XCTAssertEqual(configuration.header(named: "Authorization"), "Bearer relay-token")
    XCTAssertEqual(configuration.header(named: "x-test"), "value/one")
  }

  func testHeadersAloneDoNotEnableCollector() {
    let configuration = CollectorOTLPConfiguration(
      environment: EnvironmentValues(
        values: [
          "OTEL_EXPORTER_OTLP_HEADERS": "authorization=Bearer%20unrelated-token",
        ],
        getFromEnvironment: { _ in nil },
        getFromInfoDictionary: { _ in nil }
      ),
      logger: nil
    )

    XCTAssertNil(configuration)
  }

  func testIgnoresStandardHeadersAndProtocolForTrustedEndpoint() throws {
    let messages = LockIsolated([String]())
    let logger = Logger(printer: { message in
      messages.withValue { $0.append(message) }
    })
    let configuration = try XCTUnwrap(CollectorOTLPConfiguration(
      environment: EnvironmentValues(
        values: [
          "BUILDKITE_ANALYTICS_KEY": "run-key",
          "BUILDKITE_ANALYTICS_TOKEN": "collector-token",
          "OTEL_EXPORTER_OTLP_TRACES_HEADERS": "authorization=Bearer%20unrelated-token,x-test=value",
          "OTEL_EXPORTER_OTLP_PROTOCOL": "grpc",
        ],
        getFromEnvironment: { _ in nil },
        getFromInfoDictionary: { _ in nil }
      ),
      logger: logger
    ))
    logger.waitForLogs()

    XCTAssertEqual(configuration.endpoint.absoluteString, TestCollector.endpoint)
    XCTAssertEqual(configuration.header(named: "Buildkite-Tests-Run-Key"), "run-key")
    XCTAssertEqual(
      configuration.header(named: "Authorization"),
      #"Token token="collector-token""#
    )
    XCTAssertNil(configuration.header(named: "x-test"))
    XCTAssertTrue(messages.withValue { messages in
      messages.contains(
        "[BuildkiteTestCollector] warning: Standard OpenTelemetry exporter headers are ignored for endpoints that receive Buildkite credentials; use OTEL_EXPORTER_OTLP_TRACES_ENDPOINT or OTEL_EXPORTER_OTLP_ENDPOINT to send custom headers."
      )
    })
  }

  func testUsesCollectorCredentialsForTrustedEndpointAndCustomRunKey() throws {
    let configuration = try XCTUnwrap(CollectorOTLPConfiguration(
      environment: EnvironmentValues(
        values: [
          "BUILDKITE_ANALYTICS_KEY": "original-run-key",
          "BUILDKITE_ANALYTICS_TOKEN": "collector-token",
          "BUILDKITE_ANALYTICS_OTLP_ENDPOINT": "http://127.0.0.1:1234/v1/traces",
          "BUILDKITE_ANALYTICS_ENVIRONMENT": #"{"key":"custom-run-key"}"#,
        ],
        getFromEnvironment: { _ in nil },
        getFromInfoDictionary: { _ in nil }
      ),
      logger: nil
    ))

    XCTAssertEqual(configuration.header(named: "Buildkite-Tests-Run-Key"), "custom-run-key")
    XCTAssertEqual(
      configuration.header(named: "Authorization"),
      #"Token token="collector-token""#
    )
  }

  func testAppliesExecutionNameAffixesAndCustomRunEnvironmentOverrides() throws {
    let rootExporter = InMemoryExporter()
    let client = try XCTUnwrap(TelemetryClient.live(
      environment: EnvironmentValues(
        values: [
          "BUILDKITE_ANALYTICS_KEY": "original-run-key",
          "BUILDKITE_ANALYTICS_TOKEN": "collector-token",
          "BUILDKITE_ANALYTICS_BRANCH": "original-branch",
          "BUILDKITE_ANALYTICS_EXECUTION_NAME_PREFIX": "[ios]",
          "BUILDKITE_ANALYTICS_EXECUTION_NAME_SUFFIX": "[debug]",
          "BUILDKITE_ANALYTICS_ENVIRONMENT": #"{"key":"custom-run-key","branch":"custom-branch","buildkite.run_key":"wrong-run-key","custom.flag":true}"#,
        ],
        getFromEnvironment: { _ in nil },
        getFromInfoDictionary: { _ in nil }
      ),
      uploadTags: [:],
      logger: nil,
      rootExporter: rootExporter,
      childExporter: InMemoryExporter()
    ))
    var test = TestState(id: UUID(), className: "PaymentTests", testName: "testChargeCard")

    let executionID = client.startExecution(test)
    test.result = .passed
    client.finishExecution(executionID, test: test, tags: nil)

    let span = try XCTUnwrap(rootExporter.getFinishedSpanItems().only)
    XCTAssertEqual(span.attributes["test.case.name"], .string("[ios] PaymentTests.testChargeCard [debug]"))
    XCTAssertEqual(span.attributes[BuildkiteTelemetryAttribute.runKey], .string("custom-run-key"))
    XCTAssertEqual(span.attributes["custom.flag"], .bool(true))
    XCTAssertEqual(span.resource.attributes["vcs.ref.head.name"], .string("custom-branch"))
    XCTAssertNil(span.resource.attributes[BuildkiteTelemetryAttribute.runKey])
    XCTAssertNil(span.resource.attributes["custom.flag"])
    XCTAssertNil(span.attributes["key"])
    XCTAssertNil(span.attributes["branch"])
  }

  func testUsesProviderNativeCIRunIdentityAndKeepsOtherURLsOnExecutionRoot() throws {
    let github = try self.exportExecution(environmentValues: [
      "GITHUB_ACTION": "test",
      "GITHUB_ACTOR": "octocat",
      "GITHUB_REF_NAME": "main",
      "GITHUB_REPOSITORY": "acme/payments",
      "GITHUB_RUN_ATTEMPT": "1",
      "GITHUB_RUN_ID": "github-123",
      "GITHUB_RUN_NUMBER": "42",
      "GITHUB_SHA": "abc123",
      "GITHUB_WORKFLOW": "Tests",
    ])
    XCTAssertEqual(github.resource.attributes["cicd.pipeline.run.id"], .string("github-123"))
    XCTAssertEqual(
      github.resource.attributes["cicd.pipeline.run.url.full"],
      .string("https://github.com/acme/payments/actions/runs/github-123")
    )
    XCTAssertNil(github.attributes[BuildkiteTelemetryAttribute.runURL])

    let circle = try self.exportExecution(environmentValues: [
      "CIRCLE_BRANCH": "main",
      "CIRCLE_BUILD_NUM": "42",
      "CIRCLE_BUILD_URL": "https://circle.example/jobs/42",
      "CIRCLE_SHA1": "abc123",
      "CIRCLE_WORKFLOW_ID": "circle-123",
    ])
    XCTAssertEqual(circle.resource.attributes["cicd.pipeline.run.id"], .string("circle-123"))
    XCTAssertNil(circle.resource.attributes["cicd.pipeline.run.url.full"])
    XCTAssertEqual(
      circle.attributes[BuildkiteTelemetryAttribute.runURL],
      .string("https://circle.example/jobs/42")
    )

    let xcode = try self.exportExecution(environmentValues: [
      "CI_BRANCH": "main",
      "CI_BUILD_ID": "xcode-123",
      "CI_BUILD_NUMBER": "42",
      "CI_COMMIT": "abc123",
      "CI_PULL_REQUEST_HTML_URL": "https://github.com/acme/payments/pull/42",
      "CI_WORKFLOW": "Tests",
    ])
    XCTAssertEqual(xcode.resource.attributes["cicd.pipeline.run.id"], .string("xcode-123"))
    XCTAssertNil(xcode.resource.attributes["cicd.pipeline.run.url.full"])
    XCTAssertEqual(
      xcode.attributes[BuildkiteTelemetryAttribute.runURL],
      .string("https://github.com/acme/payments/pull/42")
    )

    let buildkite = try self.exportExecution(environmentValues: [
      "BUILDKITE_ANALYTICS_URL": "https://configured.example/run",
      "BUILDKITE_BUILD_ID": "buildkite-123",
      "BUILDKITE_BUILD_URL": "https://buildkite.example/builds/42",
    ])
    XCTAssertEqual(buildkite.resource.attributes["cicd.pipeline.run.id"], .string("buildkite-123"))
    XCTAssertEqual(
      buildkite.resource.attributes["cicd.pipeline.run.url.full"],
      .string("https://buildkite.example/builds/42")
    )
    XCTAssertEqual(
      buildkite.attributes[BuildkiteTelemetryAttribute.runURL],
      .string("https://configured.example/run")
    )
  }

  func testRetainsRequiredSynthesisAttributesAtMinimumUsefulSpanLimit() throws {
    let rootExporter = InMemoryExporter()
    let client = try XCTUnwrap(TelemetryClient.live(
      environment: self.configuredEnvironment,
      uploadTags: ["configured": "optional"],
      logger: nil,
      rootExporter: rootExporter,
      childExporter: InMemoryExporter(),
      rootSpanLimits: SpanLimits().settingAttributeCountLimit(3)
    ))
    var test = TestState(id: UUID(), className: "LimitedTests", testName: "testRequiredFields")

    let executionID = client.startExecution(test)
    test.result = .passed
    client.finishExecution(executionID, test: test, tags: ["execution": "optional"])

    let span = try XCTUnwrap(rootExporter.getFinishedSpanItems().only)
    XCTAssertEqual(span.attributes, [
      BuildkiteTelemetryAttribute.executionVia: .string("otlp"),
      BuildkiteTelemetryAttribute.runKey: .string("run-key"),
      SemanticConventions.Test.caseResultStatus.rawValue: .string("pass"),
    ])
  }

  func testBundleFlushRetriesExecutionsQueuedDuringBackoff() throws {
    let rootExporter = FailOnceExporter()
    let client = try XCTUnwrap(TelemetryClient.live(
      environment: self.configuredEnvironment,
      uploadTags: [:],
      logger: nil,
      rootExporter: rootExporter,
      childExporter: InMemoryExporter()
    ))

    for name in ["testOne", "testTwo"] {
      var test = TestState(id: UUID(), className: "RetryTests", testName: name)
      let executionID = client.startExecution(test)
      test.result = .passed
      client.finishExecution(executionID, test: test, tags: nil)
    }

    XCTAssertEqual(rootExporter.exports.count, 1)
    client.forceFlush()

    XCTAssertEqual(rootExporter.exports.count, 2)
    XCTAssertEqual(rootExporter.exports[0].map(\.name), ["test.execution"])
    XCTAssertEqual(
      rootExporter.exports[1].map(\.attributes[BuildkiteTelemetryAttribute.testName]),
      [.string("testOne"), .string("testTwo")]
    )
  }

  private var configuredEnvironment: EnvironmentValues {
    EnvironmentValues(
      values: [
        "BUILDKITE_ANALYTICS_KEY": "run-key",
        "BUILDKITE_ANALYTICS_TOKEN": "SECRET",
      ],
      getFromEnvironment: { _ in nil },
      getFromInfoDictionary: { _ in nil }
    )
  }

  private func exportExecution(environmentValues: [String: String]) throws -> SpanData {
    OpenTelemetry.registerTracerProvider(tracerProvider: DefaultTracerProvider.instance)
    let rootExporter = InMemoryExporter()
    var values = environmentValues
    values["BUILDKITE_ANALYTICS_TOKEN"] = "SECRET"
    let client = try XCTUnwrap(TelemetryClient.live(
      environment: EnvironmentValues(
        values: values,
        getFromEnvironment: { _ in nil },
        getFromInfoDictionary: { _ in nil }
      ),
      uploadTags: [:],
      logger: nil,
      rootExporter: rootExporter,
      childExporter: InMemoryExporter()
    ))
    var test = TestState(id: UUID(), className: "CITests", testName: "testIdentity")

    let executionID = client.startExecution(test)
    test.result = .passed
    client.finishExecution(executionID, test: test, tags: nil)

    return try XCTUnwrap(rootExporter.getFinishedSpanItems().only)
  }
}

private extension Array {
  var only: Element? {
    self.count == 1 ? self[0] : nil
  }
}

private extension CollectorOTLPConfiguration {
  func header(named name: String) -> String? {
    self.headers.first { $0.0.caseInsensitiveCompare(name) == .orderedSame }?.1
  }
}

private final class FailOnceExporter: SpanExporter, @unchecked Sendable {
  var exports = [[SpanData]]()

  func export(spans: [SpanData], explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
    self.exports.append(spans)
    return self.exports.count == 1 ? .failure : .success
  }

  func flush(explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
    .success
  }

  func shutdown(explicitTimeout: TimeInterval?) {}
}
