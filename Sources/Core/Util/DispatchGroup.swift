import Foundation

extension DispatchGroup {
  /// Waits synchronously for the previously submitted work to complete, and returns if the work is
  /// not completed before the specified timeout period has elapsed.
  ///
  /// - Parameter timeout: The maximum duration in seconds to wait.
  /// - Returns: A result value indicating whether the method returned due to a timeout.
  func wait(timeout seconds: TimeInterval) -> DispatchTimeoutResult {
    self.wait(timeout: .now() + .milliseconds(Int(seconds * 1000)))
  }
}
