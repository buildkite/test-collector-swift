import Foundation

/// A type used to upload traces asynchronously during a test run.
struct UploadClient {
  private var upload: (Trace) async throws -> Void
  private var waitForUploads: (TimeInterval) -> Void

  init(
    upload: @escaping (Trace) async throws -> Void,
    waitForUploads: @escaping (TimeInterval) -> Void
  ) {
    self.upload = upload
    self.waitForUploads = waitForUploads
  }

  /// Uploads a trace.
  ///
  /// - Parameter trace: The trace to upload
  func upload(trace: Trace) async throws {
    try await self.upload(trace)
  }

  /// Waits synchronously for the previously submitted uploads to complete.
  ///
  /// - Parameter timeout: The maximum duration in seconds to wait for uploads to complete.
  func waitForUploads(timeout: TimeInterval = twoMinutes) {
    self.waitForUploads(timeout)
  }
}

// Default timeout used by waitForUploads
private let twoMinutes: TimeInterval = 120
