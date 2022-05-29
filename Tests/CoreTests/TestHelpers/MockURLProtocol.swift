import Foundation
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class MockURLProtocol: URLProtocol {
  static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
  override class func canInit(with request: URLRequest) -> Bool {
    return true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }

  override func startLoading() {
    guard let handler = MockURLProtocol.requestHandler else {
      XCTFail("Received unexpected request with no handler set")
      return
    }
    do {
      let (response, data) = try handler(self.request)
      self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      self.client?.urlProtocol(self, didLoad: data)
      self.client?.urlProtocolDidFinishLoading(self)
    } catch {
      self.client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}

struct MockResponse: Equatable, Codable {
  let status: String
}

extension HTTPURLResponse {
  static func success(from url: URL = URL(string: "test")!) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
  }
}

extension InputStream {
  func read(maxLength: Int = 1024) -> Data {
    var data = Data()
    self.open()
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxLength)
    while self.hasBytesAvailable {
      let bytesRead = self.read(buffer, maxLength: maxLength)
      data.append(buffer, count: bytesRead)
    }
    buffer.deallocate()
    self.close()
    return data
  }
}
