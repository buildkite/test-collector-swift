import Foundation

/// A type returned by the analytics api after uploading test results.
struct UploadResponse: Equatable {
  /// The uploads identifier.
  var id: String

  /// The identifier for test run associated to the upload.
  var runId: String

  /// The number of individual test results that are queued for processing.
  var queued: Int

  /// The number of test results that were uploaded but will not be processed.
  var skipped: Int

  // TODO: Unsure if this is an array of strings
  /// Any errors that occurred
  var errors: [String]
}

extension UploadResponse: Decodable {
  enum CodingKeys: String, CodingKey {
    case id
    case runId = "run_id"
    case queued
    case skipped
    case errors
  }
}
