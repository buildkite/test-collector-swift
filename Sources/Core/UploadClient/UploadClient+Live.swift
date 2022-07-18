import Dispatch
import Foundation

extension UploadClient {
  /// Constructs a "live" upload client that uploads traces using an API client.
  ///
  /// - Parameters:
  ///   - api: An API client.
  ///   - logger: A logger.
  ///   - runEnvironment: The run environment to accompany uploaded traces, `nil` to use the default `RunEnvironment`.
  /// - Returns: A upload client that uses an api client.
  static func live(
    api: ApiClient,
    logger: Logger? = nil,
    runEnvironment: RunEnvironment? = nil
  ) -> UploadClient {
    let uploadTasks = DispatchGroup()

    let unwrappedRunEnvironment: RunEnvironment
    if let runEnvironment = runEnvironment {
      unwrappedRunEnvironment = runEnvironment
    } else {
      unwrappedRunEnvironment = EnvironmentValues(logger: logger).runEnvironment()
    }

    return UploadClient(
      upload: { trace in
        uploadTasks.enter()
        defer { uploadTasks.leave() }

        let testData = TestResults.json(runEnv: unwrappedRunEnvironment, data: [trace])
        logger?.debug("uploading \(testData)")

        do {
          let data = try await api.data(for: .upload(testData)).0
          guard let result = try? api.decode(data, as: UploadResponse.self) else {
            if let errorMessage = try? api.decode(data, as: UploadFailureResponse.self) {
              throw UploadError.error(message: errorMessage.message)
            } else {
              throw UploadError.unknown
            }
          }
          logger?.debug("Uploaded \(result)")
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
