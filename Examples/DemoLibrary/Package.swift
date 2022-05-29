// swift-tools-version: 5.5

import PackageDescription

let package = Package(
  name: "DemoLibrary",
  products: [
    .library(name: "DemoLibrary", targets: ["DemoLibrary"])
  ],
  dependencies: [
    .package(name: "collector-swift", path: "../../")
  ],
  targets: [
    .target(name: "DemoLibrary"),
    .testTarget(
      name: "DemoLibraryTests",
      dependencies: [
        "DemoLibrary",
        .product(name: "BuildkiteCollector", package: "collector-swift")
      ]
    )
  ]
)
