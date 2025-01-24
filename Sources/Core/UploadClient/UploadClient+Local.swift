import Foundation

extension UploadClient {
  /// Constructs a "local" upload client that save traces locally on to the disk.
  ///
  /// - Parameters:
  ///   - runEnvironment: The run environment to accompany stored traces.
  ///   - logger: A logger.
  ///   - batchSize: The maximum number of traces to be stored per file.
  ///   - fileController: A file controller object to handle data persistence.
  /// - Returns: An upload client that stores test results on to the disk.
  static func local(
    runEnvironment: RunEnvironment,
    logger: Logger? = nil,
    batchSize: Int = UploadClient.maximumBatchSize,
    fileController: FileController = .init()
  ) -> UploadClient {
    let client = LocalClient(
      runEnvironment: runEnvironment,
      logger: logger,
      batchSize: batchSize,
      fileController: fileController
    )

    return UploadClient(
      record: {
        guard runEnvironment.isCacheEnabled else { return }
        client.record(trace: $0)
      },
      waitForUploads: { _ in },
      storeData: {
        guard runEnvironment.isCacheEnabled else { return }
        client.storeData()
      }
    )
  }

  private final class LocalClient {
    let runEnvironment: RunEnvironment
    let logger: Logger?
    let batchSize: Int
    let fileController: FileController

    private let traces = LockIsolated([Trace]())

    init(
      runEnvironment: RunEnvironment,
      logger: Logger?,
      batchSize: Int,
      fileController: FileController
    ) {
      self.runEnvironment = runEnvironment
      self.logger = logger
      self.batchSize = batchSize
      self.fileController = fileController
    }

    func record(trace: Trace) {
      self.traces.withValue { traces in
        traces.append(trace)
        guard traces.count >= self.batchSize else { return }
        save(traces: traces)
        traces = []
      }
    }

    func storeData() {
      self.traces.withValue { traces in
        save(traces: traces)
        traces = []
      }
    }

    private func save(traces: [Trace]) {
      let testData = TestResults.json(runEnv: runEnvironment, data: traces)
      do {
        self.logger?.debug("Saving test data locally \(testData)")
        try saveTestData(testData)
      } catch {
        self.logger?.error("Saving test data locally failed - \(error.localizedDescription)")
      }
    }

    private func saveTestData(_ testData: TestResults) throws {
      try fileController.saveData(testData, fileName: "TestResults-\(UUID().uuidString)", fileExtension: "json")
    }
  }
}
