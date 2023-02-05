// swift-tools-version: 5.5

import PackageDescription

let package = Package(
  name: "DemoLibrary",
  platforms: [
    .macOS("10.15"),
    .iOS("13.0"),
    .tvOS("13.0"),
    .watchOS("6.0")
  ],
  products: [
    .library(name: "DemoLibrary", targets: ["DemoLibrary"])
  ],
  dependencies: [
    .package(name: "BuildkiteTestCollector", path: "../../")
  ],
  targets: [
    .target(name: "DemoLibrary"),
    .testTarget(
      name: "DemoLibraryTests",
      dependencies: ["DemoLibrary", "BuildkiteTestCollector"]
    )
  ]
)
