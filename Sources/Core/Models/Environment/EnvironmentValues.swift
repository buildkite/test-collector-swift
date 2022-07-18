import Foundation

struct EnvironmentValues {
  private var values: [String: String]

  private let getFromEnvironment: (String) -> String?
  private let getFromInfoDictionary: (String) -> String?

  var logger: Logger?

  init(
    values: [String: String] = [:],
    getFromEnvironment: @escaping (String) -> String? = getEnvironmentValue,
    getFromInfoDictionary: @escaping (String) -> String? = getInfoDictionaryValue,
    logger: Logger? = nil
  ) {
    self.values = values
    self.getFromEnvironment = getFromEnvironment
    self.getFromInfoDictionary = getFromInfoDictionary
    self.logger = logger
  }

  func bool(for key: String) -> Bool? {
    self.string(for: key).flatMap { NSString(string: $0).boolValue }
  }

  func string(for key: String) -> String? {
    let customDictionaryValue = self.values[key]
    logger?.debug("Looked in values dictionary for \(key), found: \(String(describing: customDictionaryValue))")
    if let value = customDictionaryValue {
      return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    let environmentValue = self.getFromEnvironment(key)
    logger?.debug("Looked in environment for \(key), found: \(String(describing: environmentValue))")
    if let value = environmentValue {
      return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    let infoDictionaryValue = self.getFromInfoDictionary(key)
    logger?.debug("Looked in info dictionary for \(key), found: \(String(describing: infoDictionaryValue))")
    if let value = infoDictionaryValue {
      return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    return nil
  }
}

extension EnvironmentValues {
  var isAnalyticsEnabled: Bool { self.bool(for: "BUILDKITE_ANALYTICS_ENABLED") ?? true }
  var analyticsToken: String? { self.string(for: "BUILDKITE_ANALYTICS_TOKEN") }

  var isAnalyticsDebugEnabled: Bool { self.bool(for: "BUILDKITE_ANALYTICS_DEBUG_ENABLED") ?? false }
  var analyticsDebugFilePath: String? { self.string(for: "BUILDKITE_ANALYTICS_DEBUG_FILEPATH") }

  var analyticsKey: String? { self.string(for: "BUILDKITE_ANALYTICS_KEY") }
  var analyticsUrl: String? { self.string(for: "BUILDKITE_ANALYTICS_URL") }
  var analyticsBranch: String? { self.string(for: "BUILDKITE_ANALYTICS_BRANCH") }
  var analyticsSha: String? { self.string(for: "BUILDKITE_ANALYTICS_SHA") }
  var analyticsNumber: String? { self.string(for: "BUILDKITE_ANALYTICS_NUMBER") }
  var analyticsJobId: String? { self.string(for: "BUILDKITE_ANALYTICS_JOB_ID") }
  var analyticsMessage: String? { self.string(for: "BUILDKITE_ANALYTICS_MESSAGE") }

  var buildkiteBuildId: String? { self.string(for: "BUILDKITE_BUILD_ID") }
  var buildkiteBuildUrl: String? { self.string(for: "BUILDKITE_BUILD_URL") }
  var buildkiteBranch: String? { self.string(for: "BUILDKITE_BRANCH") }
  var buildkiteCommit: String? { self.string(for: "BUILDKITE_COMMIT") }
  var buildkiteBuildNumber: String? { self.string(for: "BUILDKITE_BUILD_NUMBER") }
  var buildkiteJobId: String? { self.string(for: "BUILDKITE_JOB_ID") }
  var buildkiteMessage: String? { self.string(for: "BUILDKITE_MESSAGE") }

  var ci: String? { self.string(for: "CI") }

  var circleBuildNumber: String? { self.string(for: "CIRCLE_BUILD_NUM") }
  var circleWorkflowId: String? { self.string(for: "CIRCLE_WORKFLOW_ID") }
  var circleBuildUrl: String? { self.string(for: "CIRCLE_BUILD_URL") }
  var circleBranch: String? { self.string(for: "CIRCLE_BRANCH") }
  var circleSha: String? { self.string(for: "CIRCLE_SHA1") }

  var gitHubAction: String? { self.string(for: "GITHUB_ACTION") }
  var gitHubRef: String? { self.string(for: "GITHUB_REF") }
  var gitHubRunNumber: String? { self.string(for: "GITHUB_RUN_NUMBER") }
  var gitHubRunAttempt: String? { self.string(for: "GITHUB_RUN_ATTEMPT") }
  var gitHubRepository: String? { self.string(for: "GITHUB_REPOSITORY") }
  var gitHubRunId: String? { self.string(for: "GITHUB_RUN_ID") }
  var gitHubSha: String? { self.string(for: "GITHUB_SHA") }
}

private func getEnvironmentValue(key: String) -> String? {
  ProcessInfo.processInfo.environment[key]
}

private func getInfoDictionaryValue(key: String) -> String? {
  Bundle.main.infoDictionary?[key] as? String
}
