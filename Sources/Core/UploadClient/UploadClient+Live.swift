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
    logger: Logger? = nil,
    runEnvironment: RunEnvironment = EnvironmentValues().runEnvironment()
  ) -> UploadClient {
    let uploadTasks = DispatchGroup()

    return UploadClient(
      upload: { trace in
        uploadTasks.enter()
        defer { uploadTasks.leave() }

        let testData = TestResults.json(runEnv: runEnvironment, data: [trace])
        logger?.debug("uploading \(testData)")

        do {
          _ = try await api.data(for: .upload(testData), as: UploadResponse.self)
        } catch {
          logger?.error(error.localizedDescription)
          throw error
        }
      },
      waitForUploads: { timeout in
        let result = uploadTasks.yieldAndWait(timeout: timeout)
        if result == .timedOut {
          logger?.error("Upload client timed out before completing all uploads")
        }
      }
    )
  }
}
