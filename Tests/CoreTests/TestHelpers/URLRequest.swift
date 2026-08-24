import Foundation
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension URLRequest {
  var authorizationHeader: String? {
    self.value(forHTTPHeaderField: "Authorization")
  }

  var httpBodyDictionary: NSDictionary? {
    guard let data = self.httpBody ?? self.httpBodyStream?.read() else { return nil }
    return try? JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
  }
}

extension InputStream {
  fileprivate func read(maxLength: Int = 1024) -> Data {
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
