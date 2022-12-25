@testable import Core
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class UploadClientTests: XCTestCase {
  func testWaitSynchronouslyForUploads() throws {
    let uploadCompleted = self.expectation(description: "upload completed")
    let uploadClient = UploadClient.live(api: .fulfill(uploadCompleted, after: 0.5), runEnvironment: EnvironmentValues().runEnvironment())
    let trace = Trace(id: "id", history: .init(section: "section"))

    Task { try await uploadClient.upload(trace: trace) }
    uploadClient.waitForUploads()

    self.wait(for: [uploadCompleted], timeout: 0)
  }

  func testWaitShouldTimeout() throws {
    let uploadCompleted = self.expectation(description: "upload completed")
    uploadCompleted.isInverted = true
    let uploadClient = UploadClient.live(api: .fulfill(uploadCompleted, after: 0.5), runEnvironment: EnvironmentValues().runEnvironment())
    let trace = Trace(id: "id", history: .init(section: "section"))

    let task = Task { try await uploadClient.upload(trace: trace) }
    uploadClient.waitForUploads(timeout: 0.1)
    task.cancel()

    self.wait(for: [uploadCompleted], timeout: 1)
  }

  func testFailureResponseThrowsAsError() async throws {
    let data = try JSONEncoder().encode(UploadFailureResponse(message: "Something went wrong"))
    let api = ApiClient { _ in (data, .stub()) }
    let uploadClient = UploadClient.live(api: api, runEnvironment: EnvironmentValues().runEnvironment())
    let trace = Trace(id: "id", history: .init(section: "section"))

    let task = Task { try await uploadClient.upload(trace: trace) }
    let result = await task.result

    XCTAssertThrowsError(try result.get()) { error in
      XCTAssertTrue(error is UploadClient.UploadError)
      XCTAssertEqual(error.localizedDescription, "Something went wrong")
    }
  }
}
