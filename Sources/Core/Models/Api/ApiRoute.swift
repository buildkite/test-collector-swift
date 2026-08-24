import Foundation

/// Different endpoints for Buildkite Test Engine
///
/// Currently there is only a single upload endpoint, in the future this could be expanded to include others though. The new route would be handled in
/// `ApiClient`'s `makeRequest` function
enum ApiRoute: Equatable {
  case upload(TestResults)
}
