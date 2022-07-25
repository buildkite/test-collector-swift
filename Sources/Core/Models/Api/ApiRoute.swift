import Foundation

/// Different endpoints for the Buildkite analytics service
///
/// Currently there is only a single upload endpoint, in the future this could be expanded to include others though. The new route would be handled in
/// `ApiClient`'s `makeRequest` function
enum ApiRoute: Equatable {
  case upload(TestResults)
}
