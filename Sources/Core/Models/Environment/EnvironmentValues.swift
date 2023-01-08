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

  func string(for key: String, redactInLogs: Bool = false) -> String? {
    let customDictionaryValue = self.values[key]
    logger?.debug(debugMessage(key: key, value: customDictionaryValue, location: "CustomDictionaryValue", redactValue: redactInLogs))
    if let value = customDictionaryValue {
      return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    let environmentValue = self.getFromEnvironment(key)
    logger?.debug(debugMessage(key: key, value: environmentValue, location: "environment", redactValue: redactInLogs))
    if let value = environmentValue {
      return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    let infoDictionaryValue = self.getFromInfoDictionary(key)
    logger?.debug(debugMessage(key: key, value: infoDictionaryValue, location: "info dictionary", redactValue: redactInLogs))
    if let value = infoDictionaryValue {
      return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    return nil
  }

  private func debugMessage(key: String, value: String?, location: String, redactValue: Bool) -> String {
    let valueDescription: String
    if let value = value {
      if redactValue {
        valueDescription = "[Redacted]"
      } else {
        valueDescription = value
      }
    } else {
      valueDescription = "nil"
    }

    return "Looked in \(location) for \(key), found: \(valueDescription)"
  }
}

extension EnvironmentValues {
  var isAnalyticsEnabled: Bool { self.bool(for: "BUILDKITE_ANALYTICS_ENABLED") ?? true }
  var analyticsToken: String? { self.string(for: "BUILDKITE_ANALYTICS_TOKEN", redactInLogs: true) }

  var isAnalyticsDebugEnabled: Bool { self.bool(for: "BUILDKITE_ANALYTICS_DEBUG_ENABLED") ?? false }

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

  var executionNamePrefix: String? { self.string(for: "BUILDKITE_ANALYTICS_EXECUTION_NAME_PREFIX") }
  var executionNameSuffix: String? { self.string(for: "BUILDKITE_ANALYTICS_EXECUTION_NAME_SUFFIX") }
  
  var gitHubAction: String? { self.string(for: "GITHUB_ACTION") }
  var gitHubRefName: String? { self.string(for: "GITHUB_REF_NAME") }
  var gitHubRunNumber: String? { self.string(for: "GITHUB_RUN_NUMBER") }
  var gitHubRunAttempt: String? { self.string(for: "GITHUB_RUN_ATTEMPT") }
  var gitHubRepository: String? { self.string(for: "GITHUB_REPOSITORY") }
  var gitHubRunId: String? { self.string(for: "GITHUB_RUN_ID") }
  var gitHubSha: String? { self.string(for: "GITHUB_SHA") }
  var githubWorkflowName: String? { self.string(for: "GITHUB_WORKFLOW") }
  var githubWorkflowStartedBy: String? { self.string(for: "GITHUB_ACTOR") }

  var xcodeCommitSha: String? { self.string(for: "CI_COMMIT") }
  var xcodeBuildNumber: String? { self.string(for: "CI_BUILD_NUMBER") }
  var xcodeBuildId: String? { self.string(for: "CI_BUILD_ID") }
  var xcodeWorkflowName: String? { self.string(for: "CI_WORKFLOW") }
  // Bellow here values may not be available in all contexts, for example CI_PULL_REQUEST_HTML_URL is only available on pull requests
  var xcodeBranch: String? { self.string(for: "CI_BRANCH") }
  var xcodePullRequestURL: String? { self.string(for: "CI_PULL_REQUEST_HTML_URL") }

}

private func getEnvironmentValue(key: String) -> String? {
  ProcessInfo.processInfo.environment[key]
}

private func getInfoDictionaryValue(key: String) -> String? {
  Bundle.main.infoDictionary?[key] as? String
}
