/// A type containing a test run's metadata and test results.
///
/// This is the type expected by the analytics api.
struct TestResults: Equatable {
  /// The format for the included data
  var format: String

  /// Information used to identify the test run. Test results with matching run environments will be grouped together by the analytics api.
  var runEnv: RunEnvironment

  /// An array of traces
  var data: [Trace]

  /// Constructs test results compatible with the JSON API
  ///
  /// - Parameters:
  ///   - runEnv: The run environment for when the data was captured.
  ///   - data: An array of traces.
  /// - Returns: Test results compatible with the JSON API
  static func json(runEnv: RunEnvironment, data: [Trace]) -> TestResults {
    TestResults(format: "json", runEnv: runEnv, data: data)
  }

  /// Constructs test results compatible with the WebSocket API
  ///
  /// - Parameters:
  ///   - runEnv: The run environment for when the data was captured.
  ///   - data: An array of traces.
  /// - Returns: Test results compatible with the WebSocket API
  static func webSocket(runEnv: RunEnvironment, data: [Trace]) -> TestResults {
    TestResults(format: "websocket", runEnv: runEnv, data: data)
  }
}

extension TestResults: Encodable {
  enum CodingKeys: String, CodingKey {
    case format
    case runEnv = "run_env"
    case data
  }
}
