@testable import Core
import XCTest

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class UploadClientTests: XCTestCase {
  func testWaitSynchronouslyForUploads() throws {
    let uploadCompleted = self.expectation(description: "upload completed")
    let uploadClient = UploadClient.live(
      api: .fulfill(uploadCompleted, after: 0.5),
      runEnvironment: EnvironmentValues().runEnvironment()
    )

    uploadClient.record(trace: .mock())
    uploadClient.waitForUploads()

    self.wait(for: [uploadCompleted], timeout: 0)
  }

  func testWaitShouldTimeout() throws {
    let uploadCompleted = self.expectation(description: "upload completed")
    uploadCompleted.isInverted = true
    let uploadClient = UploadClient.live(
      api: .fulfill(uploadCompleted, after: 0.5),
      runEnvironment: EnvironmentValues().runEnvironment()
    )

    uploadClient.record(trace: .mock())
    uploadClient.waitForUploads(timeout: 0.1)

    self.wait(for: [uploadCompleted], timeout: 0)
  }

  func testFailureResponseLogsError() throws {
    let errorMessage = LockIsolated("")
    let logger = Logger(logLevel: .error) { errorMessage.setValue($0) }

    let data = try JSONEncoder().encode(UploadFailureResponse(message: "Something went wrong"))
    let api = ApiClient { _ in (data, .stub()) }

    let uploadClient = UploadClient.live(
      api: api,
      runEnvironment: EnvironmentValues().runEnvironment(),
      logger: logger
    )

    uploadClient.record(trace: .mock())

    uploadClient.waitForUploads()
    logger.waitForLogs()

    XCTAssertEqual(errorMessage.value, "[BuildkiteTestCollector] error: Upload failed - Something went wrong")
  }

  func testUploadsInBatchesOf5000ByDefault() throws {
    let testResults = LockIsolated([TestResults]())

    let api = ApiClient { route in
      if case let .upload(results) = route {
        testResults.withValue { $0.append(results) }
      }
      return (Data(), .stub())
    }

    let uploadTasks = DispatchGroup()

    let uploadClient = UploadClient.live(
      api: api,
      runEnvironment: EnvironmentValues().runEnvironment(),
      group: uploadTasks
    )

    // Record 4999 traces
    for id in 1...4999 {
      uploadClient.record(trace: .mock(id: "\(id)"))
    }

    // Wait to make sure no uploads were started
    XCTAssertEqual(uploadTasks.wait(timeout: 0.1), .success)
    XCTAssertEqual(testResults.count, 0)

    // Record one more trace to trigger the first batch of 5000
    uploadClient.record(trace: .mock(id: "5000"))

    // Wait for upload to complete
    XCTAssertEqual(uploadTasks.wait(timeout: 0.1), .success)
    XCTAssertEqual(testResults.count, 1)

    // Send the remaining traces
    for id in 5001...12345 {
      let trace = Trace(id: "\(id)", history: .init(section: "section"))
      uploadClient.record(trace: trace)
    }

    // A second batch will be sent for ids 5001...10000
    XCTAssertEqual(uploadTasks.wait(timeout: 0.1), .success)
    XCTAssertEqual(testResults.count, 2)

    // Uploads any remaining traces regardless of batch size
    uploadClient.waitForUploads()

    XCTAssertEqual(testResults.count, 3)
    XCTAssertEqual(testResults[0].data.map(\.id), (1...5000).map { "\($0)" })
    XCTAssertEqual(testResults[1].data.map(\.id), (5001...10000).map { "\($0)" })
    XCTAssertEqual(testResults[2].data.map(\.id), (10001...12345).map { "\($0)" })
  }
}

extension Trace {
  fileprivate static func mock(id: String = "id") -> Self {
    Trace(id: id, history: .init(section: "stub"))
  }
}
