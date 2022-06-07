import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension ApiClient {
  static func live(
    apiToken: String,
    baseUrl: URL = URL(string: "https://analytics-api.buildkite.com/v1/")!,
    encoder: JSONEncoder = .init(),
    decoder: JSONDecoder = .init(),
    session: ApiSession = .urlSession(.shared)
  ) -> ApiClient {
    func makeRequest(from route: ApiRoute) throws -> URLRequest {
      var request = URLRequest(url: baseUrl)
      request.setValue("Token token=\"\(apiToken)\"", forHTTPHeaderField: "Authorization")

      switch route {
      case .upload(let testData):
        let data = try encoder.encode(testData)
        request.url?.appendPathComponent("uploads")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = data
        return request
      }
    }

    return ApiClient(decoder: decoder) { route in
      let request = try makeRequest(from: route)
      return try await session.data(for: request)
    }
  }
}
