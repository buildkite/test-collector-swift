# Buildkite Test Collector for Swift

Official [Buildkite Test Analytics](https://buildkite.com/test-analytics) collector for Swift test frameworks ✨

⚒ **Supported test frameworks:** XCTest, and [more coming soon](https://github.com/buildkite/test-collector-swift/labels/test%20framework).

📦 **Supported CI systems:** Buildkite, GitHub Actions, CircleCI, and others via the `BUILDKITE_ANALYTICS_*` environment variables.

## 👉 Installing

1. [Create a test suite](https://buildkite.com/docs/test-analytics), and make note of the API token for later use.
2. Add Buildkite Test Collector to your project as a package dependency.
    
    - For SwiftPM projects, add it to the dependencies of your Package.swift and include "BuildkiteTestCollector" as a dependency for your test target:
    
       ```swift
    let package = Package(
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
    
    - For Xcode projects, from the File menu, select Add Packages... 
    <!-- Add Xcode instructions -->
 
3. Set the environment variable `BUILDKITE_ANALYTICS_TOKEN` to your API token from earlier.
  <!-- Add configuration options -->

4. Run your tests
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
