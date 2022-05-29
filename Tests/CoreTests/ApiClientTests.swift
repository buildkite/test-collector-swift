@testable import Core
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class ApiClientTests: XCTestCase {
  func testLiveApiClientWithMockUrlSession() async throws {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]

    let api = ApiClient.live(
      apiToken: "deadbeef",
      baseUrl: URL(string: "https://localhost:8080/v1")!,
      session: URLSession(configuration: configuration)
    )

    let testResults = TestResults.json(runEnv: .init(key: "key"), data: [])

    MockURLProtocol.requestHandler = { request in
      XCTAssertEqual("Token token=\"deadbeef\"", request.value(forHTTPHeaderField: "Authorization"))
      let url = try XCTUnwrap(request.url)
      XCTAssertEqual("https://localhost:8080/v1/upload", url.absoluteString)
      XCTAssertEqual("POST", request.httpMethod)
      let httpBody = try XCTUnwrap(request.httpBody ?? request.httpBodyStream?.read())
      XCTAssertEqual(
        try? JSONSerialization.jsonObject(with: httpBody, options: []) as? NSDictionary,
        ["format": "json", "run_env": ["key": "key"], "data": []]
      )
      return (.success(from: url), "{\"status\":\"success\"}".data(using: .utf8)!)
    }

    let response = try await api.data(for: .upload(testResults), as: MockResponse.self)
    XCTAssertEqual(response.value, .init(status: "success"))
  }
}
