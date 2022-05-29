import Foundation

// TODO: Store these somewhere else in an enum?
private let version = "0.1.0"
private let collector = "ios-buildkite"

extension EnvironmentValues {
  func runEnvironment(defaultKey: String = UUID().uuidString) -> RunEnvironment {
    let ciEnv = self.buildKite
      ?? self.gitHubActions
      ?? self.circleCi
      ?? self.generic(key: defaultKey)

    return RunEnvironment(
      ci: ciEnv?.ci,
      key: self.analyticsKey ?? ciEnv?.key ?? defaultKey,
      url: self.analyticsUrl ?? ciEnv?.url,
      branch: self.analyticsBranch ?? ciEnv?.branch,
      commitSha: self.analyticsSha ?? ciEnv?.commitSha,
      number: self.analyticsNumber ?? ciEnv?.number,
      jobId: self.analyticsJobId ?? ciEnv?.jobId,
      message: self.analyticsMessage ?? ciEnv?.message,
      debug: self.isAnalyticsDebugEnabled ? "true" : nil,
      version: version,
      collector: collector
    )
  }

  private var buildKite: RunEnvironment? {
    guard let buildId = self.buildkiteBuildId else { return nil }
    return RunEnvironment(
      ci: "buildkite",
      key: buildId,
      url: self.buildkiteBuildUrl,
      branch: self.buildkiteBranch,
      commitSha: self.buildkiteCommit,
      number: self.buildkiteBuildNumber,
      jobId: self.buildkiteJobId,
      message: self.buildkiteMessage
    )
  }

  private var circleCi: RunEnvironment? {
    guard
      let buildNumber = self.circleBuildNumber,
      let workFlowId = self.circleWorkflowId
    else { return nil }
    return RunEnvironment(
      ci: "circleci",
      key: "\(workFlowId)-\(buildNumber)",
      url: self.circleBuildUrl,
      branch: self.circleBranch,
      commitSha: self.circleSha,
      number: buildNumber
    )
  }

  private func generic(key: String) -> RunEnvironment? {
    guard self.ci != nil else { return nil }
    return RunEnvironment(
      ci: "generic",
      key: key
    )
  }

  private var gitHubActions: RunEnvironment? {
    guard
      let runNumber = self.gitHubRunNumber,
      let action = self.gitHubAction,
      let runAttempt = self.gitHubRunAttempt
    else { return nil }

    var url: String?
    if let repository = self.gitHubRepository, let runId = self.gitHubRunId {
      url = "https://github.com/\(repository)/actions/runs/\(runId)"
    }

    return RunEnvironment(
      ci: "github_actions",
      key: "\(action)-\(runNumber)-\(runAttempt)",
      url: url,
      branch: self.gitHubRef,
      commitSha: self.gitHubSha,
      number: runNumber
    )
  }
}
