import Dispatch
import XCTest

public struct TestCollector {
  let observer: TestObserver?

  /// Constructs a collector using the provided environment values
  ///
  /// - Parameters:
  ///   - environment: The environment values.
  ///   - logger: A logger.
  init(
    environment: EnvironmentValues,
    logger: Logger? = nil,
    uploadTags: [String: String] = [:]
  ) {
    guard environment.isAnalyticsEnabled else {
      logger?.info("TestCollector disabled. Test results will not be collected.")
      self.observer = nil
      return
    }

    let envTags = environment.analyticsTags ?? [:]
    let tags = uploadTags.merging(envTags) { _, env in env }

    let telemetry = TelemetryClient.live(
      environment: environment,
      uploadTags: tags,
      logger: logger
    )
    if telemetry == nil {
      logger?.info(
        "TestCollector requires an API token or OpenTelemetry exporter configuration. Test results will not be exported."
      )
    }

    self.observer = TestObserver(logger: logger, telemetry: telemetry)
  }

  /// Annotates the current test.
  ///
  /// The provided content is added to the collected span data and will appear in the span timeline.
  ///
  /// - Parameter content: The content of this annotation
  public func annotate(_ content: @autoclosure () -> String) {
    self.observer?.annotate(content())
  }

  /// Tags the execution of the given test case with a key-value pair.
  ///
  /// - Parameters:
  ///   - testCase: The test case to tag.
  ///   - key: The tag key.
  ///   - value: The tag value.
  public func tagExecution(testCase: XCTestCase, key: String, value: String) {
    self.observer?.setTag(for: testCase, key: key, value: value)
  }

  /// Configures the shared collector.
  ///
  /// Used by the root target to create a collector and add it to the test observation center.
  ///
  /// - Note: It is important that this method does not print to stdout eg. inside the TestCollector.init. Outputting to stdout causes
  /// an error  when using `swift test --list-tests` and `--parallel` on Linux.
  /// - Parameter uploadTags: Tags to apply to the upload. When the `BUILDKITE_ANALYTICS_TAGS` environment variable is
  ///   also set, its values take precedence over `uploadTags` for any colliding keys.
  public static func load(uploadTags: [String: String] = [:]) {
    guard self.shared == nil else { return }
    // Need to create environment first with nil logger since we need the environment to make a logger
    var environment = EnvironmentValues(logger: nil)
    let logger = Logger(logLevel: environment.isAnalyticsDebugEnabled ? .debug : .info)
    environment.logger = logger
    let collector = TestCollector(environment: environment, logger: logger, uploadTags: uploadTags)
    logger.waitForLogs() // Ensures logging is complete to avoid printing to stdout
    self.shared = collector
    self.shared?.observer.map(XCTestObservationCenter.shared.addTestObserver)
  }

  public private(set) static var shared: TestCollector?

  public static let endpoint = "https://tests-otlp.buildkite.com/v1/traces"
  static let name = "test-collector-swift"
  static let version = "2.0.0-beta.1"
}
