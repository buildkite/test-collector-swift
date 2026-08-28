import Foundation

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

  /// A message associated with the test run.
  var message: String?

  /// A value indicating if the collector ran in debug mode.
  var debug: String?

  /// A tag added to the start of the execution name.
  var executionNamePrefix: String?

  /// A tag added to the end of the execution name.
  var executionNameSuffix: String?

  /// The version of the collector used.
  var version: String?

  /// The name of the collector used.
  var collector: String?

  /// A dictionary that contains custom values associated with the test run.
  ///
  /// - Note: Used internally for testing experimental features. If an existing key
  /// is used, the custom environment value will take precedence.
  var customEnvironment: [String: AnyCodable]?
}

extension RunEnvironment {
  static let customFieldNames = Set([
    "CI", "key", "url", "branch", "commit_sha", "number", "job_id", "message", "debug",
    "execution_name_prefix", "execution_name_suffix", "version", "collector",
  ])

  mutating func applyCustomEnvironmentOverrides() {
    guard let values = self.customEnvironment else { return }

    func string(_ key: String) -> String? {
      guard let value = values[key], !(value.base is NSNull) else { return nil }
      return value.base as? String ?? value.description
    }

    self.ci = string("CI") ?? self.ci
    self.key = string("key") ?? self.key
    self.url = string("url") ?? self.url
    self.branch = string("branch") ?? self.branch
    self.commitSha = string("commit_sha") ?? self.commitSha
    self.number = string("number") ?? self.number
    self.jobId = string("job_id") ?? self.jobId
    self.message = string("message") ?? self.message
    self.debug = string("debug") ?? self.debug
    self.executionNamePrefix = string("execution_name_prefix") ?? self.executionNamePrefix
    self.executionNameSuffix = string("execution_name_suffix") ?? self.executionNameSuffix
    self.version = string("version") ?? self.version
    self.collector = string("collector") ?? self.collector
  }
}
