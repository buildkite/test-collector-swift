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
		.package(url: "https://github.com/buildkite/test-collector-swift")
	],
	targets: [
		.target(name: "MyProject"),
		.testTarget(
			name: "MyProjectTests",
			dependencies: ["MyProject", "BuildkiteTestCollector"]
		)
	]
)
```
 
### Step 2
Set the `BUILDKITE_ANALYTICS_TOKEN` secret on your CI to the API token from earlier.

### Step 3

Push your changes to a branch, and open a pull request. After a test run has been triggered, results will start appearing in your analytics dashboard. 

```bash
git checkout -b add-buildkite-test-analytics
git commit -am "Add Buildkite Test Analytics"
git push origin add-buildkite-test-analytics
```

<!-- Local run -->
  
<!-- CI run -->

## 🔍 Debugging

To enable debugging output, set the `BUILDKITE_ANALYTICS_DEBUG_ENABLED` environment variable to `true`.

## 🔜 Roadmap

See the [GitHub 'enhancement' issues](https://github.com/buildkite/test-collector-swift/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement) for planned features. Pull requests are always welcome, and we’ll give you feedback and guidance if you choose to contribute 💚

## 👩‍💻 Contributing

<!-- TODO: Create contributing doc that includes how to test cross platform etc -->

Bug reports and pull requests are welcome on GitHub at https://github.com/buildkite/test-collector-swift

## 📜 License

The package is available as open source under the terms of the [MIT License](https://github.com/buildkite/test-collector-swift/blob/main/LICENSE).
