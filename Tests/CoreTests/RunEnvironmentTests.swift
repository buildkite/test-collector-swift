@testable import Core
import XCTest

final class RunEnvironmentTests: XCTestCase {
  func testBuildkiteRunEnvironment() {
    let environmentValues = EnvironmentValues(
      values: [
        "BUILDKITE_BUILD_ID": "buildId",
        "BUILDKITE_BUILD_URL": "buildUrl",
        "BUILDKITE_BRANCH": "main",
        "BUILDKITE_COMMIT": "commitSha",
        "BUILDKITE_BUILD_NUMBER": "buildNumber",
        "BUILDKITE_JOB_ID": "jobId",
        "BUILDKITE_MESSAGE": "message",
      ],
      getFromEnvironment: { _ in nil }
    )

    XCTAssertEqual(
      environmentValues.runEnvironment(),
      RunEnvironment(
        ci: "buildkite",
        key: "buildId",
        url: "buildUrl",
        branch: "main",
        commitSha: "commitSha",
        number: "buildNumber",
        jobId: "jobId",
        message: "message",
        version: TestCollector.version,
        collector: TestCollector.name
      )
    )
  }

  func testCircleCIRunEnvironment() {
    let environmentValues = EnvironmentValues(
      values: [
        "CIRCLE_BUILD_NUM": "buildNumber",
        "CIRCLE_WORKFLOW_ID": "workflowId",
        "CIRCLE_BUILD_URL": "buildUrl",
        "CIRCLE_BRANCH": "main",
        "CIRCLE_SHA1": "commitSha",
      ],
      getFromEnvironment: { _ in nil }
    )
    XCTAssertEqual(
      environmentValues.runEnvironment(),
      RunEnvironment(
        ci: "circleci",
        key: "workflowId-buildNumber",
        url: "buildUrl",
        branch: "main",
        commitSha: "commitSha",
        number: "buildNumber",
        message: "Build #buildNumber on branch main",
        version: TestCollector.version,
        collector: TestCollector.name
      )
    )
  }

  func testGitHubRunEnvironment() {
    let environmentValues = EnvironmentValues(
      values: [
        "GITHUB_ACTION": "action",
        "GITHUB_REF_NAME": "main",
        "GITHUB_RUN_NUMBER": "runNumber",
        "GITHUB_RUN_ATTEMPT": "runAttempt",
        "GITHUB_REPOSITORY": "repository",
        "GITHUB_RUN_ID": "runId",
        "GITHUB_SHA": "commitSha",
        "GITHUB_WORKFLOW": "workflowName",
        "GITHUB_ACTOR": "username",
      ],
      getFromEnvironment: { _ in nil }
    )

    XCTAssertEqual(
      environmentValues.runEnvironment(),
      RunEnvironment(
        ci: "github_actions",
        key: "action-runNumber-runAttempt",
        url: "https://github.com/repository/actions/runs/runId",
        branch: "main",
        commitSha: "commitSha",
        number: "runNumber",
        message: "Run #runNumber attempt #runAttempt of workflowName, started by username",
        version: TestCollector.version,
        collector: TestCollector.name
      )
    )
  }

  func testXcodeCloudRunEnvironment() {
    let environmentValues = EnvironmentValues(
      values: [
        "CI_COMMIT": "commitSha",
        "CI_BUILD_NUMBER": "buildNumber",
        "CI_BUILD_ID": "buildId",
        "CI_WORKFLOW": "workflowName",
        "CI_BRANCH": "main",
        "CI_PULL_REQUEST_HTML_URL": "pullRequestUrl",
      ],
      getFromEnvironment: { _ in nil }
    )

    XCTAssertEqual(
      environmentValues.runEnvironment(),
      RunEnvironment(
        ci: "xcodeCloud",
        key: "buildId",
        url: "pullRequestUrl",
        branch: "main",
        commitSha: "commitSha",
        number: "buildNumber",
        message: "Build #buildNumber of workflow: workflowName",
        version: TestCollector.version,
        collector: TestCollector.name
      )
    )
  }

  func testJSONEncoding() throws {
    let runEnvironment = RunEnvironment(
      ci: "ci",
      key: "key",
      url: "url",
      branch: "branch",
      commitSha: "commitSha",
      number: "number",
      jobId: "jobId",
      message: "message",
      debug: "debug",
      executionNamePrefix: "executionNamePrefix",
      executionNameSuffix: "executionNameSuffix",
      version: "version",
      collector: "collector"
    )

    let data = try JSONEncoder().encode(runEnvironment)

    let json = try JSONSerialization.jsonObject(with: data)

    XCTAssertEqual(
      json as? NSDictionary,
      [
        "CI": "ci",
        "key": "key",
        "url": "url",
        "branch": "branch",
        "commit_sha": "commitSha",
        "number": "number",
        "job_id": "jobId",
        "message": "message",
        "debug": "debug",
        "execution_name_prefix": "executionNamePrefix",
        "execution_name_suffix": "executionNameSuffix",
        "version": "version",
        "collector": "collector"
      ]
    )
  }
}
