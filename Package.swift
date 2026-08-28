// swift-tools-version: 5.10

import PackageDescription

let package = Package(
  name: "BuildkiteTestCollector",
  platforms: [
    .macOS("12.0"),
    .iOS("13.0"),
    .tvOS("13.0"),
    .watchOS("6.0")
  ],
  products: [
    .library(name: "BuildkiteTestCollector", targets: ["BuildkiteTestCollector"])
  ],
  dependencies: [
    // OpenTelemetry 2.2.1 and later require a Swift 6.1-only grpc-swift release.
    .package(url: "https://github.com/open-telemetry/opentelemetry-swift", exact: "2.2.0"),
    .package(url: "https://github.com/open-telemetry/opentelemetry-swift-core", exact: "2.2.0"),
    // Keep Swift 5.10 compatibility; swift-metrics 2.8 requires Swift 6.0.
    .package(url: "https://github.com/apple/swift-metrics", exact: "2.7.1")
  ],
  targets: [
    .target(name: "BuildkiteTestCollector", dependencies: ["Core", "Loader"]),
    .target(
      name: "Core",
      dependencies: [
        .product(name: "OpenTelemetryProtocolExporterHTTP", package: "opentelemetry-swift"),
        .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift-core"),
        .product(name: "CoreMetrics", package: "swift-metrics")
      ]
    ),
    .target(name: "Loader"),
    .testTarget(name: "BuildkiteTestCollectorTests", dependencies: ["BuildkiteTestCollector"]),
    .testTarget(
      name: "CoreTests",
      dependencies: [
        "Core",
        .product(name: "InMemoryExporter", package: "opentelemetry-swift"),
        .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift-core")
      ]
    )
  ],
  swiftLanguageVersions: [.v5]
)
