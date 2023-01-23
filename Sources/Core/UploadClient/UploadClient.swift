import Foundation

/// A type used to upload traces asynchronously during a test run.
struct UploadClient {
  enum UploadError: LocalizedError {
    case error(message: String)
    case unknown

    var errorDescription: String? {
      switch self {
      case .error(let message): return message
      case .unknown: return "Unknown Error"
      }
    }
  }

  private var record: (Trace) -> Void
  private var waitForUploads: (TimeInterval) -> Void

  init(
    record: @escaping (Trace) -> Void,
    waitForUploads: @escaping (TimeInterval) -> Void
  ) {
    self.record = record
    self.waitForUploads = waitForUploads
  }

  /// Uploads a trace.
  ///
  /// - Parameter trace: The trace to upload
  func record(trace: Trace) {
    self.record(trace)
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
