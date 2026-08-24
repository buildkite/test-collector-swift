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

extension RunEnvironment: Encodable {
  struct CodingKey: Swift.CodingKey {
    var stringValue: String
    var intValue: Int? { Int(self.stringValue) }

    init(_ stringValue: String) {
      self.stringValue = stringValue
    }

    init(stringValue: String) {
      self.stringValue = stringValue
    }

    init(intValue: Int) {
      self.stringValue = String(intValue)
    }

    static var ci = Self("CI")
    static var key = Self("key")
    static var url = Self("url")
    static var branch = Self("branch")
    static var commitSha = Self("commit_sha")
    static var number = Self("number")
    static var jobId = Self("job_id")
    static var message = Self("message")
    static var debug = Self("debug")
    static var executionNamePrefix = Self("execution_name_prefix")
    static var executionNameSuffix = Self("execution_name_suffix")
    static var version = Self("version")
    static var collector = Self("collector")
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKey.self)
    try container.encodeIfPresent(self.ci, forKey: .ci)
    try container.encode(self.key, forKey: .key)
    try container.encodeIfPresent(self.url, forKey: .url)
    try container.encodeIfPresent(self.branch, forKey: .branch)
    try container.encodeIfPresent(self.commitSha, forKey: .commitSha)
    try container.encodeIfPresent(self.number, forKey: .number)
    try container.encodeIfPresent(self.jobId, forKey: .jobId)
    try container.encodeIfPresent(self.message, forKey: .message)
    try container.encodeIfPresent(self.debug, forKey: .debug)
    try container.encodeIfPresent(self.executionNamePrefix, forKey: .executionNamePrefix)
    try container.encodeIfPresent(self.executionNameSuffix, forKey: .executionNameSuffix)
    try container.encodeIfPresent(self.version, forKey: .version)
    try container.encodeIfPresent(self.collector, forKey: .collector)
    for (key, value) in self.customEnvironment ?? [:] {
      try container.encode(value, forKey: CodingKey(key))
    }
  }
}
