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
    logger: Logger? = nil
  ) {
    guard environment.isAnalyticsEnabled else {
      logger?.info("TestCollector disabled. Test results will not be collected.")
      self.observer = nil
      return
    }

    let tracer = Tracer.live()

    let uploader: UploadClient?
    if let apiToken = environment.analyticsToken, apiToken != "" {
      let api = ApiClient.live(apiToken: apiToken)
      let runEnvironment = environment.runEnvironment()
      uploader = .live(api: api, runEnvironment: runEnvironment, logger: logger)
    } else {
      logger?.info("TestCollector unable to locate API key. Test results will not be uploaded.")
      uploader = nil
    }

    self.observer = TestObserver(logger: logger, tracer: tracer, uploader: uploader)
  }

  /// Annotates the current test.
  ///
  /// The provided content is added to the collected span data and will appear in the span timeline.
  ///
  /// - Parameter content: The content of this annotation
  public func annotate(_ content: @autoclosure () -> String) {
    self.observer?.tracer.annotate(content())
  }

  /// Configures the shared collector.
  ///
  /// Used by the root target to create a collector and add it to the test observation center.
  ///
  /// - Note: It is important that this method does not print to stdout eg. inside the TestCollector.init. Outputting to stdout causes
  /// an error  when using `swift test --list-tests` and `--parallel` on Linux.
  public static func load() {
    guard self.shared == nil else { return }
    // Need to create environment first with nil logger since we need the environment to make a logger
    var environment = EnvironmentValues(logger: nil)
    let logger = Logger(logLevel: environment.isAnalyticsDebugEnabled ? .debug : .info)
    environment.logger = logger
    let collector = TestCollector(environment: environment, logger: logger)
    logger.waitForLogs() // Ensures logging is complete to avoid printing to stdout
    self.shared = collector
    self.shared?.observer.map(XCTestObservationCenter.shared.addTestObserver)
  }

  public private(set) static var shared: TestCollector?

  static let name = "test-collector-swift"
  static let version = "0.3.0"
}
