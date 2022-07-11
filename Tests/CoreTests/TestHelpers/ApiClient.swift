@testable import Core
import Foundation
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension ApiClient {
  static func fulfill(_ expectation: XCTestExpectation, after seconds: TimeInterval) -> ApiClient {
    ApiClient { _ in
      try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
      expectation.fulfill()
      return (Data(), .stub())
    }
  }
}

extension URLResponse {
  static func stub(from url: URL = URL(string: "test")!) -> URLResponse {
    URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
  }
}
