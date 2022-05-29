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
    session: URLSession = .shared
  ) -> ApiClient {
    let router = Router(apiToken: apiToken, baseUrl: baseUrl, encoder: encoder)
    return ApiClient(decoder: decoder) { route in
      let request = try router.request(for: route)

      #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
      if #available(macOS 12, iOS 15, tvOS 15, watchOS 8, *) {
        return try await session.data(for: request)
      }
      #endif

      var dataTask: URLSessionDataTask?
      let cancel: () -> Void = { dataTask?.cancel() }

      return try await withTaskCancellationHandler(
        handler: { cancel() },
        operation: {
          try await withCheckedThrowingContinuation { continuation in
            dataTask = session.dataTask(with: request) { data, response, error in
              if let data = data, let response = response {
                continuation.resume(returning: (data, response))
              } else {
                continuation.resume(throwing: error ?? URLError(.badServerResponse))
              }
            }
            dataTask?.resume()
          }
        }
      )
    }
  }
}
