/// A type containing information about the environment performing the test run.
///
/// The only required property is `key` which represents a unique identifier for a test run.
struct RunEnvironment: Equatable {
  /// The continuous integration platform.
  var ci: String?

  /// A unique identifier.
  var key: String

  /// The URL associated with the test run.
  var url: String?

  /// The branch name.
  var branch: String?

  /// The commit hash.
  var commitSha: String?

  /// The run number.
  var number: String?

  /// The job identifier.
  var jobId: String?

  /// A message associated with the test run
  var message: String?

  // TODO: Can this be a bool?
  /// A value indicating if the collector ran in debug mode.
  var debug: String?

  /// The version of the collector used.
  var version: String?

  /// The name of the collector used.
  var collector: String?
}

extension RunEnvironment: Encodable {
  enum CodingKeys: String, CodingKey {
    case ci = "CI"
    case key
    case url
    case branch
    case commitSha = "commit_sha"
    case number
    case jobId = "job_id"
    case message
    case debug
    case version
    case collector
  }
}
