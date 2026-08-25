import Core

public enum TestCollector {
  /// The default OpenTelemetry traces endpoint for Buildkite Test Engine.
  public static var endpoint: String {
    Core.TestCollector.endpoint
  }

  @available(*, deprecated, renamed: "endpoint")
  public static var baseURL: String {
    self.endpoint
  }
}
