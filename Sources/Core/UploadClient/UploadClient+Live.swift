import Dispatch
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension UploadClient {
  /// Constructs a "live" upload client that uploads traces using an API client.
  ///
  /// - Parameters:
  ///   - api: An API client.
  ///   - logger: A logger.
  ///   - runEnvironment: The run environment to accompany uploaded traces.
  ///   - batchSize: The maximum number of traces per upload.
  ///   - group: A dispatch group to associate with upload tasks.
  /// - Returns: A upload client that uses an api client.
  static func live(
    api: ApiClient,
    runEnvironment: RunEnvironment,
    logger: Logger? = nil,
    batchSize: Int = UploadClient.maximumBatchSize,
    group: DispatchGroup = DispatchGroup()
  ) -> UploadClient {
    let client = LiveClient(
      api: api,
      batchSize: batchSize,
      logger: logger,
      runEnvironment: runEnvironment,
      taskGroup: group
    )

    return UploadClient(
      record: { client.record(trace: $0) },
      waitForUploads: { client.waitForUploads(timeout: $0) },
      storeData: { } // Not storing anything as traces will be uploaded
    )
  }

  private struct LiveClient {
    let api: ApiClient
    let batchSize: Int
    let logger: Logger?
    let runEnvironment: RunEnvironment
    let taskGroup: DispatchGroup

    private let traces = LockIsolated([Trace]())

    func record(trace: Trace) {
      self.traces.withValue { traces in
        traces.append(trace)
        guard traces.count >= self.batchSize else { return }
        self.upload(traces: traces)
        traces = []
      }
    }

    private func upload(traces: [Trace]) {
      // NB: Uploads must enter the task group synchronously to ensure they are waited for
      self.taskGroup.enter()
      Task {
        defer { self.taskGroup.leave() }
        let testData = TestResults.json(runEnv: runEnvironment, data: traces)
        try await self.upload(testData: testData)
      }
    }

    private func upload(testData: TestResults) async throws {
      self.logger?.debug("Uploading \(testData)")

      var data: Data
      var response: HTTPURLResponse
      do {
        (data, response) = try await self.api.data(for: .upload(testData))
      } catch {
        self.logger?.error("Error uploading: \(error.localizedDescription)")
        throw error
      }

      // Ideally “HTTP 200 OK” etc, but maybe actually “HTTP 200 no error” etc.
      let statusString = "HTTP \(response.statusCode) \(HTTPURLResponse.localizedString(forStatusCode: response.statusCode))"

      // Currently this should get HTTP 202 Accepted, but let's be a bit permissive to future changes.
      guard (201...204).contains(response.statusCode) else {
        if let body = try? self.api.decode(data, as: UploadFailureResponse.self) {
          self.logger?.error("Unexpected \(statusString), \(body.message)")
        } else {
          self.logger?.error("Unexpected \(statusString), (no message)")
        }
        throw URLError(.badServerResponse, userInfo: [ NSLocalizedDescriptionKey: "Unexpected \(statusString)" ])
      }

      do {
        let result = try self.api.decode(data, as: UploadResponse.self)
        let uploadID = result.uploadID ?? "(missing)"
        let uploadURL = result.uploadURL ?? "(missing)"
        self.logger?.debug("\(statusString), ID: \(uploadID), URL: \(uploadURL)")
      } catch let decodingError as DecodingError {
        self.logger?.error("Warning: error decoding body of \(statusString): \(decodingError)")
        // proceed anyway, since we got an HTTP 2xx, and decoding the response isn't critical
      }
    }

    func waitForUploads(timeout: TimeInterval) {
      self.traces.withValue { traces in
        guard !traces.isEmpty else { return }
        self.upload(traces: traces)
        traces = []
      }
      let result = self.taskGroup.wait(timeout: timeout)
      if result == .timedOut {
        self.logger?.error("Upload client timed out before completing all uploads")
      }
    }
  }
}

extension UploadClient {
  // The maximum number of traces that can be sent per upload
  static let maximumBatchSize = 5000
}
