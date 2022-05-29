# **BuildkiteTestAnalytics**

## Using BuildkiteTestAnalytics in your project

Add this repository to the `Package.swift` manifest of your project:

```swift
let package = Package(
  name: "MyProject",
  dependencies: [
    .package(url: "https://github.com/buildkite/collector-swift", from: "0.1.0"),
  ],
  targets: [
    .target(name: "MyProject"),
    .testTarget(
      name: "MyProjectTests",
      dependencies: [
        "DemoLibrary",
        .product(name: "BuildkiteCollector", package: "collector-swift")
      ]
    )
  ]
)
```

Add your API token as an environment variable to the Test Environment:

```
BUILDKITE_ANALYTICS_TOKEN=<Your Test Suite API Token>
```
