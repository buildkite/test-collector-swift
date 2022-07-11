@testable import Core
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class UploadClientTests: XCTestCase {
  func testWaitSynchronouslyForUploads() throws {
    let uploadCompleted = self.expectation(description: "upload completed")
    let uploadClient = UploadClient.live(api: .fulfill(uploadCompleted, after: 0.5))
    let trace = Trace(id: "id", history: .init(section: "section"))

    Task { try await uploadClient.upload(trace: trace) }
    self.sleep(for: 0.01)
    uploadClient.waitForUploads()

    self.wait(for: [uploadCompleted], timeout: 0)
  }

  func testWaitShouldTimeout() throws {
    let uploadCompleted = self.expectation(description: "upload completed")
    uploadCompleted.isInverted = true
    let uploadClient = UploadClient.live(api: .fulfill(uploadCompleted, after: 0.5))
    let trace = Trace(id: "id", history: .init(section: "section"))

    let task = Task { try await uploadClient.upload(trace: trace) }
    self.sleep(for: 0.01)
    uploadClient.waitForUploads(timeout: 0.1)
    task.cancel()

    self.wait(for: [uploadCompleted], timeout: 1)
  }

  func testErrorResponsesAreThrowAsErrors() async throws {
    let errorMessage = "Something went wrong"
    let errorResponse = UploadFailureResponse(message: errorMessage)

    let uploadClient = UploadClient.live(
      api: .init(
        decoder: JSONDecoder(),
        request: { _ in
          (try JSONEncoder().encode(errorResponse), URLResponse(url: URL(string: "test")!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil))
        }
        )
      )
    do {
      try await uploadClient.upload(trace: Trace(id: "id", history: .init(section: "section")))
    } catch {
      guard let error = error as? UploadClient.UploadError,
            case let .error(message) = error else {
        XCTFail("Thrown error should be UploadError type")
        return
      }
      
      XCTAssertEqual(message, errorMessage)
      return
    }

    XCTFail("Did not throw error with error response")
  }
}
