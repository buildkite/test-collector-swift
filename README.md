# Buildkite Test Collector for Swift

Official [Buildkite Test Engine](https://buildkite.com/platform/test-engine/) collector for Swift test frameworks ✨

⚒ **Supported test frameworks:** XCTest, Quick, and Nimble.

📦 **Supported CI systems:** Buildkite, GitHub Actions, CircleCI, Xcode Cloud, and others via the `BUILDKITE_ANALYTICS_*` environment variables.

Each test execution is exported as a parentless OpenTelemetry `test.execution`
root span. Sampled OpenTelemetry spans created by the code under test can appear
as its children. Test execution data is submitted only through OTLP; the
collector does not use the legacy proprietary execution upload API.

The collector requires Swift 5.10 or newer. Its macOS deployment target is macOS
12 or newer.

> [!NOTE]
> The OpenTelemetry-based collector on this branch is being prepared for
> `2.0.0-beta.1` and has not been released. The installation example below
> continues to reference the latest released version, `0.6.0`.

## 👉 Installing

### Step 1

[Create a test suite](https://buildkite.com/docs/test-analytics), and copy the API token that it gives you.


#### Swift Package Manager
 
To use the Buildkite Test Collector with a SwiftPM project, add this repository to the `Package.swift` manifest and add `BuildkiteTestCollector` to any test target requiring analytics:

```swift
let package = Package(
  name: "MyProject",
  dependencies: [
    .package(url: "https://github.com/buildkite/test-collector-swift", from: "0.6.0")
  ],
  targets: [
    .target(name: "MyProject"),
    .testTarget(
      name: "MyProjectTests",
      dependencies: [
        "MyProject",
        .product(name: "BuildkiteTestCollector", package: "test-collector-swift")
      ]
    )
  ]
)
```
 
### Step 2

Set the `BUILDKITE_ANALYTICS_TOKEN` secret on your CI to the API token from earlier.

By default, traces are sent using OTLP/HTTP protobuf to
`https://tests-otlp.buildkite.com/v1/traces`. The collector adds the suite token
and run key as request headers.

To send traces through an OpenTelemetry endpoint such as the Buildkite Test
Engine Client relay, set the standard exporter variables instead:

```bash
export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT="http://127.0.0.1:4318/v1/traces"
export OTEL_EXPORTER_OTLP_TRACES_HEADERS="authorization=Bearer%20local-token"
export OTEL_EXPORTER_OTLP_TRACES_PROTOCOL="http/protobuf"
```

The signal-specific variables take precedence over
`OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_HEADERS`, and
`OTEL_EXPORTER_OTLP_PROTOCOL`. A generic OTLP endpoint has `/v1/traces`
appended. Standard endpoints receive only the explicitly configured OTLP
headers; the collector does not send the Buildkite suite token to them.
`BUILDKITE_ANALYTICS_OTLP_ENDPOINT` remains available as a trusted,
collector-specific endpoint override that receives the suite token and run key.

### Step 3

If you're testing an Xcode project there's an extra step, Xcode doesn't pass environment variables from the process to the test runner so we need to manually map them. Open your test scheme or test plan(whichever you are using) and under the environment variable section add the following entry:

key:
`BUILDKITE_ANALYTICS_TOKEN`

value:
`$(BUILDKITE_ANALYTICS_TOKEN)`

If you configure an OTLP endpoint, headers, or protocol, map those
`OTEL_EXPORTER_OTLP_TRACES_*` variables into the test runner in the same way.

The same key value pair can be specified in your main bundle's `info.plist` file if you would rather specify it there. Note variables in the environment take precedent over those in the `info.plist` file.

### Step 3.5 (Optional)

When using the default endpoint, only the analytics token is required. Supported
CI platforms can pass extra information to enrich the reports, such as commit
messages, branch names, and build numbers. Open your test scheme or test plan
again and add the following key-value pairs for your CI platform.

**Buildkite**

```
Key: BUILDKITE_BUILD_ID, Value: $(BUILDKITE_BUILD_ID)
Key: BUILDKITE_BUILD_URL, Value: $(BUILDKITE_BUILD_URL)
Key: BUILDKITE_BRANCH, Value: $(BUILDKITE_BRANCH)
Key: BUILDKITE_COMMIT, Value: $(BUILDKITE_COMMIT)
Key: BUILDKITE_BUILD_NUMBER, Value: $(BUILDKITE_BUILD_NUMBER)
Key: BUILDKITE_JOB_ID, Value: $(BUILDKITE_JOB_ID)
Key: BUILDKITE_STEP_ID, Value: $(BUILDKITE_STEP_ID)
Key: BUILDKITE_MESSAGE, Value: $(BUILDKITE_MESSAGE)
Key: BUILDKITE_ORGANIZATION_SLUG, Value: $(BUILDKITE_ORGANIZATION_SLUG)
Key: BUILDKITE_TEST_ENGINE_SUITE_SLUG, Value: $(BUILDKITE_TEST_ENGINE_SUITE_SLUG)
Key: TRACEPARENT, Value: $(TRACEPARENT)
Key: TRACESTATE, Value: $(TRACESTATE)
```

**Circle CI**

```
Key: CIRCLE_BUILD_NUM, Value: $(CIRCLE_BUILD_NUM)
Key: CIRCLE_WORKFLOW_ID, Value: $(CIRCLE_WORKFLOW_ID)
Key: CIRCLE_BUILD_URL, Value: $(CIRCLE_BUILD_URL)
Key: CIRCLE_BRANCH, Value: $(CIRCLE_BRANCH)
Key: CIRCLE_SHA1, Value: $(CIRCLE_SHA1)
```

**GitHub Actions**

```
Key: GITHUB_ACTION, Value: $(GITHUB_ACTION)
Key: GITHUB_REF_NAME, Value: $(GITHUB_REF_NAME)
Key: GITHUB_RUN_NUMBER, Value: $(GITHUB_RUN_NUMBER)
Key: GITHUB_RUN_ATTEMPT, Value: $(GITHUB_RUN_ATTEMPT)
Key: GITHUB_REPOSITORY, Value: $(GITHUB_REPOSITORY)
Key: GITHUB_RUN_ID, Value: $(GITHUB_RUN_ID)
Key: GITHUB_SHA, Value: $(GITHUB_SHA)
Key: GITHUB_WORKFLOW, Value: $(GITHUB_WORKFLOW)
Key: GITHUB_ACTOR, Value: $(GITHUB_ACTOR)
```

**Xcode Cloud**

```
Key: CI_COMMIT, Value: $(CI_COMMIT)
Key: CI_BUILD_NUMBER, Value: $(CI_BUILD_NUMBER)
Key: CI_BUILD_ID, Value: $(CI_BUILD_ID)
Key: CI_WORKFLOW, Value: $(CI_WORKFLOW)
Key: CI_BRANCH, Value: $(CI_BRANCH)
Key: CI_PULL_REQUEST_HTML_URL, Value: $(CI_PULL_REQUEST_HTML_URL)
```

The same key value pairs can be specified in your main bundle's `info.plist` file if you would rather specify them there. Note variables in the environment take precedent over those in the `info.plist` file.
### Step 4

Push your changes to a branch, and open a pull request. After a test run has been triggered, results will start appearing in your Test Engine dashboard.

```bash
git checkout -b add-buildkite-test-engine
git commit -am "Add Buildkite Test Engine"
git push origin add-buildkite-test-engine
```

## 🏷 Tagging

You can tag test executions with key-value pairs to filter and group results in [Test Engine](https://buildkite.com/docs/test-engine/test-suites/tags).

### Run-level tags

Run-level tags apply to all test executions in a run. Set the `BUILDKITE_ANALYTICS_TAGS` environment variable to a JSON object:

```bash
export BUILDKITE_ANALYTICS_TAGS='{"host.arch":"arm64","cloud.region":"us-east-1"}'
```

If you're using an Xcode project, add this to your test scheme or test plan environment variables like the other `BUILDKITE_ANALYTICS_*` variables.

Run-level tags can also be set programmatically by passing them to `load`. Environment variable tags take precedence over programmatic tags when keys collide:

```swift
TestCollector.load(uploadTags: ["host.arch": "arm64"])
```

Run tags are exported as `buildkite.tag.<key>` resource attributes.

### Execution-level tags

Tag individual tests from within a test method using the `tagExecution` extension on `XCTestCase`:

```swift
class PaymentTests: XCTestCase {
    func testChargeCard() {
        self.tagExecution("suite", "smoke")
        self.tagExecution("feature", "payments")

        // ... test code ...
    }
}
```

The existing `tagExecution` API is unchanged. Execution tags are exported as
`buildkite.tag.<key>` attributes on that test's root span.

## OpenTelemetry behavior and delivery

The collector creates each `test.execution` span through a private AlwaysOn
provider, so it remains a trace root regardless of an application's sampling
configuration. When Buildkite Agent trace context is available, the execution
links to the job span instead of becoming its child. If the test suite has an
OpenTelemetry SDK provider, the collector adds a forwarding processor without
replacing its sampler or exporters. Otherwise, it installs a provider so spans
created under a test can be exported as execution children.

While the endpoint is healthy, finishing a test waits for its root span to be
accepted by the configured OTLP endpoint. After a failure, subsequent roots stay
in the collector's in-memory queue while export attempts back off for 10, 20,
30, and then at most 60 seconds. The bundle-end flush always makes an immediate
final attempt. When the endpoint is the Test Engine Client relay, acceptance
transfers the span to the longer-lived parent process, which protects completed
executions from an XCTest runner restart.

This is not disk-backed delivery. A hard exit before a test finishes, a process
exit while the endpoint remains unavailable, or a machine restart can still
lose spans. An ambiguous network timeout may also result in a retry after the
server accepted the first request.

## 🔍 Debugging

To enable debugging output, set the `BUILDKITE_ANALYTICS_DEBUG_ENABLED` environment variable to `true`. This also needs
to be set in your test scheme or test plan if you're using an Xcode project.

The library uses the presence/absence of certain environment variables to determine which CI platform it's running on, if you turn on debugging you'll see the library looking and not finding some of these keys, this is intended behaviour. Failing to find the values for your CI platform would indicate an issue though.

## 🔜 Roadmap

See the [GitHub 'enhancement' issues](https://github.com/buildkite/bktest/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement) for planned features. Pull requests are always welcome, and we’ll give you feedback and guidance if you choose to contribute 💚

## 👩‍💻 Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md).

## 🚀 Releasing

Releases are generated from the monorepo and mirrored to the standalone
SwiftPM repository. See the monorepo's
[collector release guide](https://github.com/buildkite/bktest/blob/main/RELEASING.md#swift-swift-package-manager).

## 📜 License

The package is available as open source under the terms of the [MIT License](https://github.com/buildkite/bktest/blob/main/test-collector-swift/LICENSE).
