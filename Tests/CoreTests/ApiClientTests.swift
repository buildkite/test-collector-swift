@testable import Core
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class ApiClientTests: XCTestCase {
  func testApiClientMakesUploadRequest() async throws {
    struct Response: Decodable { var status: String }
    let server = MockServer(responses: .json("{\"status\":\"OK\"}"))
    let api = ApiClient.live(apiToken: "token", session: server.session)
    let results = TestResults.json(runEnv: .init(key: "key"), data: [])

    let (value, _) = try await api.data(for: .upload(results), as: Response.self)

    XCTAssertEqual(value.status, "OK")
    server.received { request in
      XCTAssertEqual("https://analytics-api.buildkite.com/v1/uploads", request.url?.absoluteString)
      XCTAssertEqual("Token token=\"token\"", request.authorizationHeader)
      XCTAssertEqual("POST", request.httpMethod)
      XCTAssertEqual(
        ["format": "json", "run_env": ["key": "key"], "data": []],
        request.httpBodyDictionary
      )
    }
  }
}
