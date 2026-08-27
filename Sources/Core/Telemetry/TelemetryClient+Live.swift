import Foundation
import OpenTelemetryApi
import OpenTelemetryProtocolExporterCommon
import OpenTelemetryProtocolExporterHttp
import OpenTelemetrySdk

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

enum BuildkiteTelemetryAttribute {
  static let annotation = "buildkite.annotation"
  static let buildNumber = "buildkite.build_number"
  static let collectorName = "buildkite.collector.name"
  static let collectorVersion = "buildkite.collector.version"
  static let executionExternalID = "buildkite.test.execution.external_id"
  static let executionLocation = "buildkite.test.location"
  static let executionScope = "buildkite.test.scope"
  static let executionVia = "buildkite.execution.via"
  static let frameworkName = "buildkite.test.framework.name"
  static let jobID = "buildkite.job_id"
  static let message = "buildkite.message"
  static let runKey = "buildkite.run_key"
  static let runURL = "buildkite.run_url"
  static let stepID = "buildkite.step_id"
  static let tagPrefix = "buildkite.tag."
  static let testName = "buildkite.test.name"
}

private enum TelemetryValue {
  static let executionVia = "otlp"
  static let frameworkName = "xctest"
  static let rootSpanName = "test.execution"
  static let skippedResult = "skipped"
  static let unsetResult = "unset"
}

struct CollectorOTLPConfiguration {
  let endpoint: URL
  let headers: [(String, String)]
  let runEnvironment: RunEnvironment

  init?(
    environment: EnvironmentValues,
    logger: Logger?
  ) {
    var runEnvironment = environment.runEnvironment()
    runEnvironment.applyCustomEnvironmentOverrides()
    let rawHeaders = environment.otelTracesHeaders ?? environment.otelHeaders
    // Standard headers alone must not enable collection or select the OTLP
    // specification's localhost default. They may be process-wide settings for
    // unrelated telemetry and are safe to use only with an explicit standard endpoint.
    let hasExplicitConfiguration = environment.otelTracesEndpoint != nil
      || environment.otelEndpoint != nil
      || environment.analyticsOTLPEndpoint != nil

    guard environment.analyticsToken != nil || hasExplicitConfiguration else { return nil }

    let endpoint: URL
    let usesBuildkiteCredentials: Bool
    if let value = environment.otelTracesEndpoint {
      guard let url = Self.absoluteURL(value) else {
        logger?.error("OpenTelemetry traces endpoint is not a valid absolute URL")
        return nil
      }
      endpoint = url
      usesBuildkiteCredentials = false
    } else if let value = environment.analyticsOTLPEndpoint {
      guard let url = Self.absoluteURL(value) else {
        logger?.error("OpenTelemetry traces endpoint is not a valid absolute URL")
        return nil
      }
      endpoint = url
      usesBuildkiteCredentials = true
    } else if let value = environment.otelEndpoint {
      guard let url = Self.absoluteURL(value) else {
        logger?.error("OpenTelemetry endpoint is not a valid absolute URL")
        return nil
      }
      endpoint = url.appendingPathComponent("v1/traces")
      usesBuildkiteCredentials = false
    } else {
      endpoint = URL(string: TestCollector.endpoint)!
      usesBuildkiteCredentials = true
    }

    if !usesBuildkiteCredentials,
       let protocolName = environment.otelTracesProtocol ?? environment.otelProtocol,
       protocolName.lowercased() != "http/protobuf" {
      logger?.error(
        "Unsupported OpenTelemetry traces protocol \(protocolName); expected http/protobuf"
      )
      return nil
    }

    var headers = [(String, String)]()
    if usesBuildkiteCredentials {
      headers.append(("Buildkite-Tests-Run-Key", runEnvironment.key))
      if let token = environment.analyticsToken {
        headers.append(("Authorization", "Token token=\"\(token)\""))
      }
      if rawHeaders != nil {
        logger?.warning(
          "Standard OpenTelemetry exporter headers are ignored for endpoints that receive Buildkite credentials; use OTEL_EXPORTER_OTLP_TRACES_ENDPOINT or OTEL_EXPORTER_OTLP_ENDPOINT to send custom headers."
        )
      }
    } else if let rawHeaders {
      guard let parsedHeaders = Self.parseHeaders(rawHeaders) else {
        logger?.error("OpenTelemetry exporter headers are invalid")
        return nil
      }
      headers = parsedHeaders
    }

    self.endpoint = endpoint
    self.headers = headers
    self.runEnvironment = runEnvironment
  }

  private static func absoluteURL(_ value: String) -> URL? {
    guard let url = URL(string: value), url.scheme != nil, url.host != nil else { return nil }
    return url
  }

  private static func parseHeaders(_ value: String) -> [(String, String)]? {
    let entries = value.split(separator: ",", omittingEmptySubsequences: false)
    guard !entries.isEmpty else { return nil }

    var headers: [(String, String)] = []
    for entry in entries {
      let parts = entry.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
      guard parts.count == 2 else { return nil }

      let name = String(parts[0]).removingPercentEncoding?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      let value = String(parts[1]).removingPercentEncoding?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      guard !name.isEmpty, !value.isEmpty else { return nil }

      headers.removeAll { $0.0.caseInsensitiveCompare(name) == .orderedSame }
      headers.append((name, value))
    }
    return headers
  }
}

private final class SynchronousOtlpTraceExporter: SpanExporter, @unchecked Sendable {
  private let exporter: OtlpHttpTraceExporter
  private let httpClient: SynchronousHTTPClient

  init(endpoint: URL, configuration: OtlpConfiguration) {
    let httpClient = SynchronousHTTPClient(timeout: configuration.timeout)
    self.httpClient = httpClient
    self.exporter = OtlpHttpTraceExporter(
      endpoint: endpoint,
      config: configuration,
      httpClient: httpClient,
      envVarHeaders: nil
    )
  }

  func export(spans: [SpanData], explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
    self.httpClient.prepare()
    _ = self.exporter.export(spans: spans, explicitTimeout: explicitTimeout)
    return self.httpClient.result
  }

  func flush(explicitTimeout: TimeInterval?) -> SpanExporterResultCode {
    self.exporter.flush(explicitTimeout: explicitTimeout)
  }

  func shutdown(explicitTimeout: TimeInterval?) {
    self.exporter.shutdown(explicitTimeout: explicitTimeout)
  }
}

private final class SynchronousHTTPClient: HTTPClient {
  private let lock = NSLock()
  private let session: URLSession
  private var wasAccepted: Bool?

  init(timeout: TimeInterval) {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = timeout
    configuration.timeoutIntervalForResource = timeout
    configuration.urlCache = nil
    self.session = URLSession(configuration: configuration)
  }

  func prepare() {
    self.lock.lock()
    self.wasAccepted = nil
    self.lock.unlock()
  }

  var result: SpanExporterResultCode {
    self.lock.lock()
    defer { self.lock.unlock() }
    return self.wasAccepted == true ? .success : .failure
  }

  func send(
    request: URLRequest,
    completion: @escaping (Result<HTTPURLResponse, Error>) -> Void
  ) {
    let semaphore = DispatchSemaphore(value: 0)
    let task = self.session.dataTask(with: request) { [weak self] _, response, error in
      let httpResponse = response as? HTTPURLResponse
      let accepted = error == nil
        && httpResponse.map { (200..<300).contains($0.statusCode) } == true

      self?.lock.lock()
      self?.wasAccepted = accepted
      self?.lock.unlock()

      // The collector owns failed-span requeueing. Always report transport
      // completion to the upstream exporter so it does not queue a second copy.
      completion(.success(httpResponse ?? HTTPURLResponse(
        url: request.url!,
        statusCode: 500,
        httpVersion: nil,
        headerFields: nil
      )!))
      semaphore.signal()
    }
    task.resume()
    semaphore.wait()
  }
}

extension TelemetryClient {
  static func live(
    environment: EnvironmentValues,
    uploadTags: [String: String],
    logger: Logger?,
    rootExporter: (any SpanExporter)? = nil,
    childExporter: (any SpanExporter)? = nil,
    rootSpanLimits: SpanLimits = SpanLimits()
  ) -> TelemetryClient? {
    guard let configuration = CollectorOTLPConfiguration(
      environment: environment,
      logger: logger
    ) else { return nil }

    let exporterConfiguration = OtlpConfiguration(
      timeout: 10,
      compression: .gzip,
      headers: configuration.headers,
      exportAsJson: false
    )
    let makeExporter = {
      SynchronousOtlpTraceExporter(
        endpoint: configuration.endpoint,
        configuration: exporterConfiguration
      ) as any SpanExporter
    }
    let live = LiveTelemetryClient(
      configuration: configuration,
      environment: environment,
      uploadTags: uploadTags,
      logger: logger,
      rootExporter: rootExporter ?? makeExporter(),
      childExporter: childExporter ?? makeExporter(),
      rootSpanLimits: rootSpanLimits
    )

    return TelemetryClient(
      start: live.startExecution,
      annotate: live.annotate,
      finish: live.finishExecution,
      flush: live.forceFlush
    )
  }
}

private final class LiveTelemetryClient {
  private static let providerEnvironmentLock = NSLock()

  private let attachedChildProviders = LockIsolated([TracerProviderSdk]())
  private let childForwarder: ExecutionChildSpanProcessor
  private let childProviderResource: Resource
  private let executionProvider: TracerProviderSdk
  private let executionNamePrefix: String?
  private let executionNameSuffix: String?
  private let executionAttributes: [String: AttributeValue]
  private let runKey: String
  private let logger: Logger?
  private let registry = ExecutionTraceRegistry()
  private let reportedUnsupportedChildProvider = LockIsolated(false)
  private let spans = LockIsolated([UUID: any Span]())
  private let tracer: any OpenTelemetryApi.Tracer
  private let jobSpanContext: SpanContext?
  private let executionContextManager: ExecutionContextManager

  init(
    configuration: CollectorOTLPConfiguration,
    environment: EnvironmentValues,
    uploadTags: [String: String],
    logger: Logger?,
    rootExporter: any SpanExporter,
    childExporter: any SpanExporter,
    rootSpanLimits: SpanLimits
  ) {
    self.executionNamePrefix = configuration.runEnvironment.executionNamePrefix
    self.executionNameSuffix = configuration.runEnvironment.executionNameSuffix
    self.runKey = configuration.runEnvironment.key
    self.logger = logger
    self.jobSpanContext = Self.jobSpanContext(environment: environment)

    let resource = Self.providerResource(
      configuration: configuration,
      environment: environment
    )
    self.executionAttributes = Self.executionAttributes(
      configuration: configuration,
      environment: environment,
      uploadTags: uploadTags
    )
    self.childProviderResource = resource
    let rootProcessor = SynchronousExecutionSpanProcessor(exporter: rootExporter, logger: logger)
    self.executionProvider = Self.makeProvider(
      resource: resource,
      processor: rootProcessor,
      spanLimits: rootSpanLimits
    )
    self.tracer = self.executionProvider.get(
      instrumentationName: TestCollector.name,
      instrumentationVersion: TestCollector.version
    )

    let childProcessor = BatchSpanProcessor(
      spanExporter: childExporter,
      scheduleDelay: 1,
      exportTimeout: 30,
      maxQueueSize: 8192,
      maxExportBatchSize: 512
    )
    let forwarder = ExecutionChildSpanProcessor(processor: childProcessor, registry: self.registry)
    self.childForwarder = forwarder
    self.executionContextManager = ExecutionContextManager(
      delegate: OpenTelemetry.instance.contextProvider
    )
    self.executionContextManager.setContextReadHandler { [weak self] in
      self?.attachChildForwarder()
    }
    OpenTelemetry.registerContextManager(contextManager: self.executionContextManager)
    self.attachChildForwarder()
  }

  func startExecution(_ test: TestState) -> UUID {
    self.attachChildForwarder()

    let qualifiedTestName = [
      self.executionNamePrefix,
      "\(test.className).\(test.testName)",
      self.executionNameSuffix,
    ].compactMap { $0 }.joined(separator: " ")
    let builder = self.tracer
      .spanBuilder(spanName: TelemetryValue.rootSpanName)
      .setNoParent()

    for (key, value) in self.executionAttributes {
      builder.setAttribute(key: key, value: value)
    }

    builder
      .setAttribute(key: BuildkiteTelemetryAttribute.executionScope, value: test.className)
      .setAttribute(key: BuildkiteTelemetryAttribute.testName, value: test.testName)
      .setAttribute(
        key: BuildkiteTelemetryAttribute.executionExternalID,
        value: test.id.uuidString
      )
      .setAttribute(
        key: SemanticConventions.Test.caseName.rawValue,
        value: qualifiedTestName
      )
      .setAttribute(key: SemanticConventions.Test.suiteName.rawValue, value: test.className)
      // The Swift SDK keeps the most recently set attributes when the span's
      // start-time attribute limit is exceeded. Set the three synthesis fields
      // last so even a limit of three still produces a usable execution.
      .setAttribute(key: BuildkiteTelemetryAttribute.executionVia, value: TelemetryValue.executionVia)
      .setAttribute(
        key: BuildkiteTelemetryAttribute.runKey,
        value: self.runKey
      )
      // Reserve the result's place before test code can consume the remaining
      // attribute budget. finishExecution replaces this placeholder.
      .setAttribute(
        key: SemanticConventions.Test.caseResultStatus.rawValue,
        value: TelemetryValue.unsetResult
      )

    if let jobSpanContext = self.jobSpanContext {
      builder.addLink(spanContext: jobSpanContext)
    }

    let span = builder.startSpan()
    self.registry.insert(span.context.traceId)
    self.spans.withValue { $0[test.id] = span }
    self.executionContextManager.setExecutionSpan(span)
    return test.id
  }

  func annotate(executionID: UUID, content: String) {
    guard let span = self.spans.withValue({ $0[executionID] }) else { return }
    span.addEvent(
      name: "test.annotation",
      attributes: [BuildkiteTelemetryAttribute.annotation: .string(content)]
    )
  }

  func finishExecution(executionID: UUID, test: TestState, tags: [String: String]?) {
    guard let span = self.spans.withValue({ $0.removeValue(forKey: executionID) }) else { return }

    for (key, value) in tags ?? [:] {
      span.setAttribute(key: BuildkiteTelemetryAttribute.tagPrefix + key, value: value)
    }

    let result = test.result ?? .failed
    span.setAttribute(
      key: SemanticConventions.Test.caseResultStatus.rawValue,
      value: Self.resultStatus(result)
    )

    if let location = test.issues.first?.sourceCodeContext.location {
      span.setAttribute(key: SemanticConventions.Code.filePath.rawValue, value: location.filePath)
      span.setAttribute(key: SemanticConventions.Code.lineNumber.rawValue, value: Int(location.line))
      span.setAttribute(
        key: BuildkiteTelemetryAttribute.executionLocation,
        value: "\(location.fileName):\(location.line)"
      )
    }

    if result == .failed {
      let reason = Self.failureReason(test.issues)
      span.status = .error(description: reason)
      for issue in test.issues {
        var attributes: [String: AttributeValue] = [
          SemanticConventions.Exception.message.rawValue: .string(issue.description),
        ]
        let backtrace = issue.sourceCodeContext.callStack.enumerated()
          .map { "\($0.offset) \($0.element)" }
          .joined(separator: "\n")
        if !backtrace.isEmpty {
          attributes[SemanticConventions.Exception.stacktrace.rawValue] = .string(backtrace)
        }
        if let error = issue.associatedError {
          attributes[SemanticConventions.Exception.type.rawValue] = .string(
            String(reflecting: type(of: error))
          )
        }
        span.addEvent(
          name: SemanticConventions.Exception.exception.rawValue,
          attributes: attributes
        )
      }
    }

    self.executionContextManager.removeExecutionSpan(span)
    self.registry.remove(span.context.traceId)
    span.end()
  }

  func forceFlush() {
    self.executionProvider.forceFlush(timeout: 30)
    self.childForwarder.forceFlush(timeout: 30)
  }

  private func attachChildForwarder() {
    let globalProvider = OpenTelemetry.instance.tracerProvider
    if globalProvider is DefaultTracerProvider {
      let provider = Self.makeProvider(
        resource: self.childProviderResource,
        processor: self.childForwarder
      )
      self.attachedChildProviders.withValue { $0.append(provider) }
      OpenTelemetry.registerTracerProvider(tracerProvider: provider)
    } else if let provider = globalProvider as? TracerProviderSdk {
      let needsProcessor = self.attachedChildProviders.withValue { providers in
        guard !providers.contains(where: { $0 === provider }) else { return false }
        providers.append(provider)
        return true
      }
      if needsProcessor {
        provider.addSpanProcessor(self.childForwarder)
      }
    } else {
      let shouldReport = self.reportedUnsupportedChildProvider.withValue { reported in
        guard !reported else { return false }
        reported = true
        return true
      }
      if shouldReport {
        self.logger?.error(
          "OpenTelemetry child span export is disabled because the existing tracer provider cannot accept a span processor"
        )
      }
    }
  }

  private static func resultStatus(_ result: TestResult) -> String {
    switch result {
    case .passed:
      return SemanticConventions.Test.CaseResultStatusValues.pass.description
    case .failed:
      return SemanticConventions.Test.CaseResultStatusValues.fail.description
    case .skipped:
      return TelemetryValue.skippedResult
    }
  }

  private static func failureReason(_ issues: [TestIssue]) -> String {
    if issues.count > 1 {
      return "\(issues.count) failures: \(issues.map(\.compactDescription).joined(separator: ", "))"
    }
    return issues.first?.compactDescription ?? "Test failed"
  }

  private static func makeProvider(
    resource: Resource,
    processor: any SpanProcessor,
    spanLimits: SpanLimits = SpanLimits()
  ) -> TracerProviderSdk {
    self.withoutInheritedTraceContext {
      TracerProviderBuilder()
        .with(resource: resource)
        .with(spanLimits: spanLimits)
        .with(sampler: Samplers.alwaysOn)
        .add(spanProcessor: processor)
        .build()
    }
  }

  private static func withoutInheritedTraceContext<T>(_ operation: () -> T) -> T {
    self.providerEnvironmentLock.lock()
    defer { self.providerEnvironmentLock.unlock() }

    let names = ["TRACEPARENT", "TRACESTATE"]
    let previous = Dictionary(uniqueKeysWithValues: names.map { name in
      (name, getenv(name).map { String(cString: $0) })
    })
    names.forEach { unsetenv($0) }
    defer {
      for name in names {
        if let value = previous[name] ?? nil {
          setenv(name, value, 1)
        } else {
          unsetenv(name)
        }
      }
    }
    return operation()
  }

  // A resource identifies producer-wide entities shared by every span from the
  // provider. Test Engine run fields and tags belong to each execution root.
  private static func providerResource(
    configuration: CollectorOTLPConfiguration,
    environment: EnvironmentValues
  ) -> Resource {
    let run = configuration.runEnvironment
    let pipelineRun = Self.ciPipelineRun(run: run, environment: environment)
    var attributes = [String: AttributeValue]()

    func set(_ key: String, _ value: String?) {
      if let value, Self.validAttributeKey(key) {
        attributes[key] = .string(value)
      }
    }

    set(SemanticConventions.Service.name.rawValue, environment.testEngineSuiteSlug)
    set(SemanticConventions.Service.namespace.rawValue, environment.buildkiteOrganizationSlug)
    set(SemanticConventions.Cicd.pipelineRunId.rawValue, pipelineRun.id)
    if pipelineRun.id != nil {
      set(SemanticConventions.Cicd.pipelineRunUrlFull.rawValue, pipelineRun.url)
    }
    set(SemanticConventions.Cicd.workerId.rawValue, environment.buildkiteAgentId)
    set(SemanticConventions.Vcs.refHeadName.rawValue, run.branch)
    set(SemanticConventions.Vcs.refHeadRevision.rawValue, run.commitSha)
    if run.branch != nil {
      set(
        SemanticConventions.Vcs.refType.rawValue,
        environment.buildkiteTag == nil ? "branch" : "tag"
      )
    }

    return EnvVarResource.get().merging(other: Resource(attributes: attributes))
  }

  // These fields describe each test execution, not the provider that emitted
  // its child spans. Configure-level tags are set on every root; per-test tags
  // are applied at finish time and override matching configure-level tags.
  private static func executionAttributes(
    configuration: CollectorOTLPConfiguration,
    environment: EnvironmentValues,
    uploadTags: [String: String]
  ) -> [String: AttributeValue] {
    let run = configuration.runEnvironment
    let pipelineRun = Self.ciPipelineRun(run: run, environment: environment)
    var attributes = [String: AttributeValue]()

    func set(_ key: String, _ value: String?) {
      if let value, Self.validAttributeKey(key) {
        attributes[key] = .string(value)
      }
    }

    set(BuildkiteTelemetryAttribute.runKey, run.key)
    if run.url != pipelineRun.url {
      set(BuildkiteTelemetryAttribute.runURL, run.url)
    }
    set(BuildkiteTelemetryAttribute.buildNumber, run.number)
    set(BuildkiteTelemetryAttribute.jobID, run.jobId)
    set(BuildkiteTelemetryAttribute.stepID, environment.buildkiteStepId)
    set(BuildkiteTelemetryAttribute.message, run.message)
    set(BuildkiteTelemetryAttribute.collectorName, run.collector)
    set(BuildkiteTelemetryAttribute.collectorVersion, run.version)
    set(BuildkiteTelemetryAttribute.frameworkName, TelemetryValue.frameworkName)

    for (key, value) in uploadTags {
      set(BuildkiteTelemetryAttribute.tagPrefix + key, value)
    }
    for (key, value) in run.customEnvironment ?? [:]
      where !RunEnvironment.customFieldNames.contains(key) && Self.validAttributeKey(key)
    {
      attributes[key] = AttributeValue(value.base) ?? .string(value.description)
    }

    return attributes
  }

  // Provider-native CI identity is distinct from the Test Engine run key.
  private static func ciPipelineRun(
    run: RunEnvironment,
    environment: EnvironmentValues
  ) -> (id: String?, url: String?) {
    switch run.ci {
    case "buildkite":
      return (environment.buildkiteBuildId, environment.buildkiteBuildUrl)
    case "github_actions":
      let id = environment.gitHubRunId
      let url = environment.gitHubRepository.flatMap { repository in
        id.map { "https://github.com/\(repository)/actions/runs/\($0)" }
      }
      return (id, url)
    case "circleci":
      return (environment.circleWorkflowId, nil)
    case "xcodeCloud":
      return (environment.xcodeBuildId, nil)
    default:
      return (nil, nil)
    }
  }

  private static func validAttributeKey(_ key: String) -> Bool {
    !key.isEmpty && key.count <= 255 && key.unicodeScalars.allSatisfy { (32...126).contains($0.value) }
  }

  private static func jobSpanContext(environment: EnvironmentValues) -> SpanContext? {
    guard let traceParent = environment.traceParent else { return nil }
    let carrier = [
      "traceparent": traceParent,
      "tracestate": environment.traceState ?? "",
    ]
    return W3CTraceContextPropagator().extract(carrier: carrier, getter: DictionaryGetter())
  }

  private struct DictionaryGetter: Getter {
    func get(carrier: [String: String], key: String) -> [String]? {
      carrier[key].map { [$0] }
    }
  }
}
