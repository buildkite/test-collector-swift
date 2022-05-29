// swift-tools-version: 5.5

import PackageDescription

let package = Package(
  name: "collector-swift",
  platforms: [
    .macOS("10.15"),
    .iOS("13.0"),
    .tvOS("13.0"),
    .watchOS("6.0")
  ],
  products: [
    .library(name: "BuildkiteCollector", targets: ["BuildkiteCollector"])
  ],
  targets: [
    .target(name: "BuildkiteCollector", dependencies: ["Core", "Loader"]),
    .target(name: "Core"),
    .target(name: "Loader"),
    .testTarget(name: "BuildkiteCollectorTests", dependencies: ["BuildkiteCollector"]),
    .testTarget(name: "CoreTests", dependencies: ["Core"])
  ]
)
