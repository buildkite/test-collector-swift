import Foundation

/// A type used to upload traces asynchronously during a test run.
struct UploadClient {
  enum UploadError: LocalizedError {
    case error(message: String)
    case unknown

    var errorDescription: String? {
      switch self {
      case let .error(message): return message
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

  /// Records a trace to be included in the next upload.
  ///
  /// - Parameter trace: The trace to record
  func record(trace: Trace) {
    self.record(trace)
  }

  /// Waits synchronously for the previously submitted traces to be uploaded.
  ///
  /// - Parameter timeout: The maximum duration in seconds to wait for uploads to complete.
  func waitForUploads(timeout: TimeInterval = twoMinutes) {
    self.waitForUploads(timeout)
  }
}

// Default timeout used by waitForUploads
private let twoMinutes: TimeInterval = 120
