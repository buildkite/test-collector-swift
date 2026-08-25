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
        "BUILDKITE_BUILD_ID": "build-id",
        "BUILDKITE_BUILD_NUMBER": "123",
        "BUILDKITE_BUILD_URL": "https://buildkite.example/builds/123",
        "BUILDKITE_BRANCH": "main",
        "BUILDKITE_COMMIT": "abc123",
        "BUILDKITE_JOB_ID": "job-id",
        "BUILDKITE_STEP_ID": "step-id",
        "BUILDKITE_TEST_ENGINE_SUITE_SLUG": "swift-suite",
      ],
      getFromEnvironment: { _ in nil },
      getFromInfoDictionary: { _ in nil }
    )
    let client = try XCTUnwrap(TelemetryClient.live(
      environment: environment,
      uploadTags: ["language": "swift"],
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
    client.annotate("checkpoint", executionID: executionID)
    test.result = .passed
    client.finishExecution(executionID, test: test, tags: ["feature": "payments"])

    let span = try XCTUnwrap(rootExporter.getFinishedSpanItems().only)
    XCTAssertEqual(span.name, "test.execution")
    XCTAssertNil(span.parentSpanId)
    XCTAssertEqual(span.attributes[BuildkiteTelemetryAttribute.executionVia], .string("otlp"))
    XCTAssertEqual(span.attributes[BuildkiteTelemetryAttribute.executionScope], .string("PaymentTests"))
    XCTAssertEqual(span.attributes[BuildkiteTelemetryAttribute.testName], .string("testChargeCard"))
    XCTAssertEqual(span.attributes["test.case.result.status"], .string("pass"))
    XCTAssertEqual(span.attributes["buildkite.tag.feature"], .string("payments"))
    XCTAssertEqual(span.resource.attributes[BuildkiteTelemetryAttribute.runKey], .string("run-key"))
    XCTAssertEqual(span.resource.attributes[BuildkiteTelemetryAttribute.buildID], .string("build-id"))
    XCTAssertEqual(span.resource.attributes["buildkite.tag.language"], .string("swift"))
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

  #if canImport(os.activity)
  func testExportsSpansCreatedUnderTheActiveExecutionAsChildren() throws {
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
  }
  #endif

  func testUsesStandardTraceEndpointAndHeadersOverCollectorToken() throws {
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
    XCTAssertEqual(configuration.header(named: "Buildkite-Tests-Run-Key"), "run-key")
    XCTAssertEqual(configuration.header(named: "Authorization"), "Bearer relay-token")
    XCTAssertEqual(configuration.header(named: "x-test"), "value/one")
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
