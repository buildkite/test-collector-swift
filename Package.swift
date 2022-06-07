// swift-tools-version: 5.5

import PackageDescription

let package = Package(
  name: "BuildkiteTestCollector",
  platforms: [
    .macOS("10.15"),
    .iOS("13.0"),
    .tvOS("13.0"),
    .watchOS("6.0")
  ],
  products: [
    .library(name: "BuildkiteTestCollector", targets: ["BuildkiteTestCollector"])
  ],
  targets: [
    .target(name: "BuildkiteTestCollector", dependencies: ["Core", "Loader"]),
    .target(name: "Core"),
    .target(name: "Loader"),
    .testTarget(name: "BuildkiteTestCollectorTests", dependencies: ["BuildkiteTestCollector"]),
    .testTarget(name: "CoreTests", dependencies: ["Core"])
  ]
)
