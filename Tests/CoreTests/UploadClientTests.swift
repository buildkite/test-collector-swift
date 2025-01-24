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
    let api = ApiClient { _ in (data, .stub(status: 500)) }

    let uploadClient = UploadClient.live(
      api: api,
      runEnvironment: EnvironmentValues().runEnvironment(),
      logger: logger
    )

    uploadClient.record(trace: .mock())

    uploadClient.waitForUploads()
    logger.waitForLogs()

    // this varies e.g. macOS “internal server error” vs linux “Internal Server Error”
    let statusName = HTTPURLResponse.localizedString(forStatusCode: 500)
    XCTAssertEqual(errorMessage.value, "[BuildkiteTestCollector] error: Unexpected HTTP 500 \(statusName), Something went wrong")
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

  func testSaveData() throws {
    let fileController = FileControllerSpy()
    var environment = EnvironmentValues().runEnvironment()
    environment.isCacheEnabled = true

    let uploadClient = UploadClient.local(
      runEnvironment: environment,
      fileController: fileController
    )

    uploadClient.record(trace: .mock())
    uploadClient.saveData()

    fileController.savedFileURLs.forEach {
      XCTAssertTrue(fileController.fileExists(at: $0.path))
    }
  }

  func testSaveDataInBatchesOf5000ByDefault() throws {
    let fileController = FileControllerSpy()
    var environment = EnvironmentValues().runEnvironment()
    environment.isCacheEnabled = true

    let uploadClient = UploadClient.local(
      runEnvironment: environment,
      fileController: fileController
    )

    // Record 4999 traces
    for id in 1...4999 {
      uploadClient.record(trace: .mock(id: "\(id)"))
    }

    // Make sure that saved data is not called yet
    XCTAssertEqual(fileController.savedFileURLs.count, 0)

    // Record one more trace to trigger the first batch of 5000
    uploadClient.record(trace: .mock(id: "5000"))

    // Make sure that the first batch of data is saved
    XCTAssertEqual(fileController.savedFileURLs.count, 1)
    XCTAssertTrue(fileController.fileExists(at: fileController.savedFileURLs[0].path))

    // Send the remaining traces
    for id in 5001...12345 {
      let trace = Trace(id: "\(id)", history: .init(section: "section"))
      uploadClient.record(trace: trace)
    }

    // Save any remaining traces regardless of batch size
    uploadClient.saveData()

    fileController.savedFileURLs.forEach {
      XCTAssertTrue(fileController.fileExists(at: $0.path))
    }

    XCTAssertEqual(
      (fileController.savedData[0] as? TestResults)?.data.map(\.id),
      (1...5000).map { "\($0)" }
    )
    XCTAssertEqual(
      (fileController.savedData[1] as? TestResults)?.data.map(\.id),
      (5001...10000).map { "\($0)" }
    )
    XCTAssertEqual(
      (fileController.savedData[2] as? TestResults)?.data.map(\.id),
      (10001...12345).map { "\($0)" }
    )
  }

  func testSaveDataShouldNotSaveWhenCachingIsDisabled() {
    let fileController = FileControllerSpy()
    var environment = EnvironmentValues().runEnvironment()
    environment.isCacheEnabled = false

    let uploadClient = UploadClient.local(
      runEnvironment: environment,
      fileController: fileController
    )

    uploadClient.record(trace: .mock())
    uploadClient.saveData()

    XCTAssertEqual(fileController.savedData.count, 0)
  }

  final class FileControllerSpy: FileController {
    private(set) var savedData: [Encodable] = []
    private(set) var savedFileURLs: [URL] = []

    override func saveData<T: Encodable>(_ data: T, fileName: String, fileExtension: String) throws -> URL {
      let fileURL = try super.saveData(data, fileName: fileName, fileExtension: fileExtension)
      savedFileURLs.append(fileURL)
      savedData.append(data)
      return fileURL
    }
  }
}

extension Trace {
  fileprivate static func mock(id: String = "id") -> Self {
    Trace(id: id, history: .init(section: "stub"))
  }
}
