# Changelog

## Unreleased

- Submit XCTest executions as OpenTelemetry root spans instead of proprietary JSON uploads
- Export run and execution tags as `buildkite.tag.*` attributes
- Support standard OTLP/HTTP exporter configuration and child-span forwarding
- Require Swift 5.10 and macOS 12 or newer

## 0.6.0

- Add tagging support at upload and execution levels
- Fix macOS CI: update test matrix to Swift 5.10, 6.1, 6.2

## 0.5.0

- Handle updated Upload API response with more permissive parsing and better errors
- Update documentation to use "Test Engine" instead of "Test Analytics"
- Add CONTRIBUTING.md
- Update CI to macOS 15 with newer Swift & Xcode versions

## 0.4.1

- Add `location` field to test executions
