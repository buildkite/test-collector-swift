// swift-tools-version: 6.0

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
    .package(url: "https://github.com/open-telemetry/opentelemetry-swift", exact: "2.3.0"),
    .package(url: "https://github.com/open-telemetry/opentelemetry-swift-core", exact: "2.3.0"),
    // Keep Swift 6.0 compatibility; swift-metrics 2.9 requires Swift 6.1.
    .package(url: "https://github.com/apple/swift-metrics", exact: "2.8.0")
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
  swiftLanguageModes: [.v5]
)
