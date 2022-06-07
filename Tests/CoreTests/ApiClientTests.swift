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
      return ("{\"status\":\"OK\"}".data(using: .utf8)!, .success())
    }
    let api = ApiClient.live(apiToken: "token", session: session)
    let results = TestResults.json(runEnv: .init(key: "key"), data: [])

    let (value, _) = try await api.data(for: .upload(results), as: Response.self)

    XCTAssertEqual(value.status, "OK")
    XCTAssertEqual(requests.count, 1)
    let request = try XCTUnwrap(requests.first)
    XCTAssertEqual(request.url?.absoluteString, "https://analytics-api.buildkite.com/v1/uploads")
    XCTAssertEqual(request.authorizationHeader, "Token token=\"token\"")
    XCTAssertEqual(request.httpMethod, "POST")
    XCTAssertEqual(
      request.httpBodyDictionary,
      ["format": "json", "run_env": ["key": "key"], "data": []]
    )
  }
}
