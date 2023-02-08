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

  private var upload: (Trace) -> Task<Void, Error>
  private var waitForUploads: (TimeInterval) -> Void

  init(
    upload: @escaping (Trace) -> Task<Void, Error>,
    waitForUploads: @escaping (TimeInterval) -> Void
  ) {
    self.upload = upload
    self.waitForUploads = waitForUploads
  }

  /// Uploads a trace.
  ///
  /// - Parameter trace: The trace to upload
  /// - Returns: A `Task` responsible for performing the upload.
  @discardableResult
  func upload(trace: Trace) -> Task<Void, Error> {
    self.upload(trace)
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
