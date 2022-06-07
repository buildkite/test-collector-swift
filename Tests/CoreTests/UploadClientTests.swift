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
}
