import Dispatch
import Foundation

extension UploadClient {
  /// Constructs a "live" upload client that uploads traces using an API client.
  ///
  /// - Parameters:
  ///   - api: An API client.
  ///   - logger: A logger.
  ///   - runEnvironment: The run environment to accompany uploaded traces.
  /// - Returns: A upload client that uses an api client.
  static func live(
    api: ApiClient,
    runEnvironment: RunEnvironment,
    logger: Logger? = nil
  ) -> UploadClient {
    let client = LiveClient(api: api, logger: logger, runEnvironment: runEnvironment)

    return UploadClient(
      upload: { client.upload(trace: $0) },
      waitForUploads: { client.waitForUploads(timeout: $0) }
    )
  }

  private struct LiveClient {
    let api: ApiClient
    let logger: Logger?
    let runEnvironment: RunEnvironment
    let taskGroup = DispatchGroup()

    func upload(trace: Trace) -> Task<Void, Error> {
      // NB: Uploads must enter the task group synchronously to ensure they are waited for
      self.taskGroup.enter()
      return Task {
        defer { self.taskGroup.leave() }
        let testData = TestResults.json(runEnv: runEnvironment, data: [trace])
        try await self.upload(testData: testData)
      }
    }

    private func upload(testData: TestResults) async throws {
      self.logger?.debug("uploading \(testData)")

      do {
        let (data, _) = try await self.api.data(for: .upload(testData))
        guard let result = try? self.api.decode(data, as: UploadResponse.self) else {
          if let errorMessage = try? self.api.decode(data, as: UploadFailureResponse.self) {
            throw UploadError.error(message: errorMessage.message)
          } else {
            throw UploadError.unknown
          }
        }
        self.logger?.debug("Finished Upload, got response: \(result)")
      } catch {
        self.logger?.error("Failed to upload result, got error: \(error.localizedDescription)")
        throw error
      }
    }

    func waitForUploads(timeout: TimeInterval) {
      let result = self.taskGroup.wait(timeout: timeout)
      if result == .timedOut {
        self.logger?.error("Upload client timed out before completing all uploads")
      }
    }
  }
}
