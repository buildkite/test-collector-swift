# Buildkite Test Collector for Swift (Beta)

Official [Buildkite Test Analytics](https://buildkite.com/test-analytics) collector for Swift test frameworks ✨

⚒ **Supported test frameworks:** XCTest, and [more coming soon](https://github.com/buildkite/test-collector-swift/labels/test%20framework).

📦 **Supported CI systems:** Buildkite, GitHub Actions, CircleCI, and others via the `BUILDKITE_ANALYTICS_*` environment variables.

## 👉 Installing

### Step 1

[Create a test suite](https://buildkite.com/docs/test-analytics), and copy the API token that it gives you.


#### Swift Package Manager
 
To use the Buildkite Test Collector with a SwiftPM project, add this repository to the `Package.swift` manifest and add `BuildkiteTestCollector` to any test target requiring analytics:

```swift
let package = Package(
  name: "MyProject",
  dependencies: [
    .package(url: "https://github.com/buildkite/test-collector-swift", from: "0.1.1")
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

### Step 3

If you're testing an Xcode project there's an extra step, Xcode doesn't pass environment variables from the process to the test runner so we need to manually map them. Open your test scheme or test plan(whichever you are using) and under the environment variable section add the following entry:

key:
`BUILDKITE_ANALYTICS_TOKEN`

value:
`$(BUILDKITE_ANALYTICS_TOKEN)`

The same key value pair can be specified in your main bundle's `info.plist` file if you would rather specify them there. Note variables in the environment take precedent over those in the `info.plist` file.

### Step 3.5 (Optional)

The only required environment variable is the analytics token but if you're using one of the supported CI platforms they can pass extra information to the test-collector to enrich the reports. Things like commit messages, branch names, build numbers, etc. Open your test scheme or test plan again and add the following key value pairs depending on your CI platform.

**Buildkite**

```
Key: BUILDKITE_BUILD_ID, Value: $(BUILDKITE_BUILD_ID)
Key: BUILDKITE_BUILD_URL, Value: $(BUILDKITE_BUILD_URL)
Key: BUILDKITE_BRANCH, Value: $(BUILDKITE_BRANCH)
Key: BUILDKITE_COMMIT, Value: $(BUILDKITE_COMMIT)
Key: BUILDKITE_BUILD_NUMBER, Value: $(BUILDKITE_BUILD_NUMBER)
Key: BUILDKITE_JOB_ID, Value: $(BUILDKITE_JOB_ID)
Key: BUILDKITE_MESSAGE, Value: $(BUILDKITE_MESSAGE)
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
Key: GITHUB_REF, Value: $(GITHUB_REF)
Key: GITHUB_RUN_NUMBER, Value: $(GITHUB_RUN_NUMBER)
Key: GITHUB_RUN_ATTEMPT, Value: $(GITHUB_RUN_ATTEMPT)
Key: GITHUB_REPOSITORY, Value: $(GITHUB_REPOSITORY)
Key: GITHUB_RUN_ID, Value: $(GITHUB_RUN_ID)
Key: GITHUB_SHA, Value: $(GITHUB_SHA)
```

The same key value pairs can be specified in your main bundle's `info.plist` file if you would rather specify them there. Note variables in the environment take precedent over those in the `info.plist` file.
### Step 4

Push your changes to a branch, and open a pull request. After a test run has been triggered, results will start appearing in your analytics dashboard.

```bash
git checkout -b add-buildkite-test-analytics
git commit -am "Add Buildkite Test Analytics"
git push origin add-buildkite-test-analytics
```

## 🔍 Debugging

To enable debugging output, set the `BUILDKITE_ANALYTICS_DEBUG_ENABLED` environment variable to `true`. This also needs
to be set in your test scheme or test plan if you're using an Xcode project.

The library uses the presence/absence of certain environment variables to determine which CI platform it's running on, if you turn on debugging you'll see the library looking and not finding some of these keys, this is intended behaviour. Failing to find the values for your CI platform would indicate an issue though.

## 🔜 Roadmap

See the [GitHub 'enhancement' issues](https://github.com/buildkite/test-collector-swift/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement) for planned features. Pull requests are always welcome, and we’ll give you feedback and guidance if you choose to contribute 💚

## 👩‍💻 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/buildkite/test-collector-swift

## 📜 License

The package is available as open source under the terms of the [MIT License](https://github.com/buildkite/test-collector-swift/blob/main/LICENSE).
