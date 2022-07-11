import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct ApiClient {
  let decoder: JSONDecoder
  var request: (ApiRoute) async throws -> (Data, URLResponse)

  init(
    decoder: JSONDecoder = JSONDecoder(),
    request: @escaping (ApiRoute) async throws -> (Data, URLResponse)
  ) {
    self.request = request
    self.decoder = decoder
  }

  func data(for route: ApiRoute) async throws -> (value: Data, response: URLResponse) {
    try await self.request(route)
  }

  func data<Value: Decodable>(
    for route: ApiRoute,
    as type: Value.Type
  ) async throws -> (value: Value, response: URLResponse) {
    let (data, response) = try await self.request(route)
    let value = try decode(data, as: type)
    return (value, response)
  }

  func decode<Value: Decodable>(_ data: Data, as type: Value.Type) throws -> Value {
    try self.decoder.decode(type, from: data)
  }
}
