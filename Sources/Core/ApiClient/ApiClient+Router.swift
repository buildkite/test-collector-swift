import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension ApiClient {
  /// A type that creates URL requests from api routes.
  struct Router {
    var request: (ApiRoute) throws -> URLRequest

    init(
      apiToken: String,
      baseUrl: URL,
      encoder: JSONEncoder
    ) {
      self.request = { route in
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
    }

    func request(for route: ApiRoute) throws -> URLRequest {
      try self.request(route)
    }
  }
}
