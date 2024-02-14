import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct ApiSession {
  var data: (URLRequest) async throws -> (Data, URLResponse)

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    try await self.data(request)
  }
}

extension ApiSession {
  static func urlSession(_ session: URLSession) -> ApiSession {
    ApiSession { request in
      #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
      if #available(macOS 12, iOS 15, tvOS 15, watchOS 8, *) {
        return try await session.data(for: request)
      }
      #endif

      var dataTask: URLSessionDataTask?
      let cancel: () -> Void = { dataTask?.cancel() }

      return try await withTaskCancellationHandler(
        operation: {
          try await withCheckedThrowingContinuation { continuation in
            dataTask = session.dataTask(with: request) { data, response, error in
              if let data, let response {
                continuation.resume(returning: (data, response))
              } else {
                continuation.resume(throwing: error ?? URLError(.badServerResponse))
              }
            }
            dataTask?.resume()
          }
        },
        onCancel: { cancel() }
      )
    }
  }
}
