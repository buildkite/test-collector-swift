import Foundation
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class MockServer {
  let session: URLSession
  private var responses: [MockURLResponse] = []
  private var requests: [URLRequest] = []

  init(responses: MockURLResponse...) {
    assert(MockURLProtocol.requestHandler == nil, "Only a single mock server allowed")

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    self.session = URLSession(configuration: configuration)
    self.responses = responses

    struct UnexpectedRequest: Error {}
    MockURLProtocol
      .requestHandler = { [unowned self] (request: URLRequest) throws -> (Data, HTTPURLResponse) in
        guard !self.responses.isEmpty else {
          XCTFail("Received unexpected request")
          throw UnexpectedRequest()
        }

        self.requests.append(request)
        let response = self.responses.removeFirst()

        switch response {
        case .json(let string):
          return (string.data(using: .utf8)!, .success(from: URL(string: "mock")!))
        }
      }
  }

  deinit {
    XCTAssert(self.requests.isEmpty, "All requests must be verified")
    XCTAssert(self.responses.isEmpty, "All responses must be requested")
    MockURLProtocol.requestHandler = nil
  }

  func received(verifyRequest: (URLRequest) throws -> Void) rethrows {
    guard !self.requests.isEmpty else {
      XCTFail("Received unexpected request")
      return
    }
    try verifyRequest(self.requests.removeFirst())
  }
}

private class MockURLProtocol: URLProtocol {
  static var requestHandler: ((URLRequest) throws -> (Data, HTTPURLResponse))?

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
      let (data, response) = try handler(self.request)
      self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      self.client?.urlProtocol(self, didLoad: data)
      self.client?.urlProtocolDidFinishLoading(self)
    } catch {
      self.client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}

enum MockURLResponse: Equatable {
  case json(String)
}

extension HTTPURLResponse {
  static func success(from url: URL = URL(string: "test")!) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
  }
}
