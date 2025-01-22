import Foundation

/// Response from Test Engine API after uploading test results.
struct UploadResponse: Equatable {
  /// The UUID allocated to this upload
  var uploadID: String?

  /// The URL that can be used to view upload details
  var uploadURL: String?
}

extension UploadResponse: Decodable {
  enum CodingKeys: String, CodingKey {
    case uploadID = "upload_id"
    case uploadURL = "upload_url"
  }
}

struct UploadFailureResponse: Equatable, Codable {
  var message: String
}
