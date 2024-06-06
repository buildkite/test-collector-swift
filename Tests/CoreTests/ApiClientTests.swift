@testable import Core
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class ApiClientTests: XCTestCase {
  func testApiClientMakesUploadRequest() async throws {
    struct Response: Decodable { var status: String }
    var requests = [URLRequest]()
    let session = ApiSession { request in
      requests.append(request)
      return ("{\"status\":\"OK\"}".data(using: .utf8)!, .stub())
    }
    let api = ApiClient.live(
      apiToken: "token",
      baseURL: URL(string: "http://api.test.com/")!,
      session: session
    )
    let results = TestResults.json(runEnv: .init(key: "key", isCacheEnabled: true), data: [])

    let (value, _) = try await api.data(for: .upload(results), as: Response.self)

    XCTAssertEqual(value.status, "OK")
    XCTAssertEqual(requests.count, 1)
    let request = try XCTUnwrap(requests.first)
    XCTAssertEqual(request.url?.absoluteString, "http://api.test.com/uploads")
    XCTAssertEqual(request.authorizationHeader, "Token token=\"token\"")
    XCTAssertEqual(request.httpMethod, "POST")
    XCTAssertEqual(
      request.httpBodyDictionary,
      ["format": "json", "run_env": ["key": "key", "isCacheEnabled": "true"], "data": NSArray()]
    )
  }
}
