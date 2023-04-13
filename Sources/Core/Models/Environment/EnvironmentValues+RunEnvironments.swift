import Foundation

extension EnvironmentValues {
  func runEnvironment(defaultKey: String = UUID().uuidString) -> RunEnvironment {
    let ciEnv = self.buildkite
      ?? self.gitHubActions
      ?? self.circleCi
      ?? self.xcodeCloud
      ?? self.generic(key: defaultKey)

    let runEnvironment = RunEnvironment(
      ci: ciEnv?.ci,
      key: self.analyticsKey ?? ciEnv?.key ?? defaultKey,
      url: self.analyticsUrl ?? ciEnv?.url,
      branch: self.analyticsBranch ?? ciEnv?.branch,
      commitSha: self.analyticsSha ?? ciEnv?.commitSha,
      number: self.analyticsNumber ?? ciEnv?.number,
      jobId: self.analyticsJobId ?? ciEnv?.jobId,
      message: self.analyticsMessage ?? ciEnv?.message,
      debug: self.isAnalyticsDebugEnabled ? "true" : nil,
      executionNamePrefix: self.executionNamePrefix,
      executionNameSuffix: self.executionNameSuffix,
      version: TestCollector.version,
      collector: TestCollector.name,
      customEnvironment: self.customEnvironment
    )

    logger?.debug("\(runEnvironment)")

    return runEnvironment
  }

  private var buildkite: RunEnvironment? {
    guard let buildId = self.buildkiteBuildId else { return nil }

    let runEnvironment = RunEnvironment(
      ci: "buildkite",
      key: buildId,
      url: self.buildkiteBuildUrl,
      branch: self.buildkiteBranch,
      commitSha: self.buildkiteCommit,
      number: self.buildkiteBuildNumber,
      jobId: self.buildkiteJobId,
      message: self.buildkiteMessage
    )

    logger?.debug("Successfully found Buildkite RunEnvironment")

    return runEnvironment
  }

  private var circleCi: RunEnvironment? {
    guard
      let buildNumber = self.circleBuildNumber,
      let workFlowId = self.circleWorkflowId
    else { return nil }

    let runEnvironment = RunEnvironment(
      ci: "circleci",
      key: "\(workFlowId)-\(buildNumber)",
      url: self.circleBuildUrl,
      branch: self.circleBranch,
      commitSha: self.circleSha,
      number: buildNumber,
      message: "Build #\(buildNumber) on branch \(self.circleBranch ?? "[Unknown branch]")"
    )

    logger?.debug("Successfully found Circle CI RunEnvironment")

    return runEnvironment
  }

  private func generic(key: String) -> RunEnvironment? {
    guard self.ci != nil else { return nil }

    logger?.debug("Falling back to generic RunEnvironment")

    return RunEnvironment(
      ci: "generic",
      key: key
    )
  }

  private var gitHubActions: RunEnvironment? {
    guard
      let runNumber = self.gitHubRunNumber,
      let action = self.gitHubAction,
      let runAttempt = self.gitHubRunAttempt,
      let workflowName = self.githubWorkflowName,
      let startedBy = self.githubWorkflowStartedBy
    else { return nil }

    var url: String?
    if let repository = self.gitHubRepository, let runId = self.gitHubRunId {
      url = "https://github.com/\(repository)/actions/runs/\(runId)"
    }
    let message = "Run #\(runNumber) attempt #\(runAttempt) of \(workflowName), started by \(startedBy)"

    let runEnvironment = RunEnvironment(
      ci: "github_actions",
      key: "\(action)-\(runNumber)-\(runAttempt)",
      url: url,
      branch: self.gitHubRefName,
      commitSha: self.gitHubSha,
      number: runNumber,
      message: message
    )

    logger?.debug("Successfully found Github RunEnvironment")

    return runEnvironment
  }

  private var xcodeCloud: RunEnvironment? {
    guard
      let commitHash = self.xcodeCommitSha,
      let buildNumber = self.xcodeBuildNumber,
      let buildID = self.xcodeBuildId,
      let workflowName = self.xcodeWorkflowName
    else { return nil }

    let message = "Build #\(buildNumber) of workflow: \(workflowName)"

    let runEnvironment = RunEnvironment(
      ci: "xcodeCloud",
      key: buildID,
      url: self.xcodePullRequestURL,
      branch: self.xcodeBranch,
      commitSha: commitHash,
      number: buildNumber,
      message: message
    )

    logger?.debug("Successfully found Xcode Cloud RunEnvironment")

    return runEnvironment
  }
}
