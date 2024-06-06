import Foundation

class FileController {
  private let fileManager = FileManager.default

  /// Saves the given data object into a local file directory.
  ///
  /// - Parameters:
  ///   - data: The data object to be saved on to the disk.
  ///   - fileName: The name to be assigned to the saved object.
  /// - Returns: The location of where the file is written to.
  @discardableResult
  func saveData<T: Encodable>(
    _ data: T,
    fileName: String,
    fileExtension: String
  ) throws -> URL {
    let testCollectorDirectory = try getTestCollectorDirectory()

    if !fileManager.fileExists(atPath: testCollectorDirectory.relativePath) {
      try fileManager.createDirectory(
        at: testCollectorDirectory,
        withIntermediateDirectories: false,
        attributes: nil
      )
    }

    let fileURL = testCollectorDirectory.appendingPathComponent(fileName + ".\(fileExtension)")
    let data = try JSONEncoder().encode(data)
    try data.write(to: fileURL, options: .atomic)
    return fileURL
  }

  /// Checks whether a file exists at the given path.
  /// - Returns: A boolean value representing whether the file exists.
  func fileExists(at path: String) -> Bool {
    fileManager.fileExists(atPath: path)
  }

  /// Removes item at the given path.
  func removeItem(at path: String) throws {
    try? fileManager.removeItem(atPath: path)
  }

  private func getTestCollectorDirectory() throws -> URL {
    let rootFolder = try fileManager.url(
      for: .documentDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    return rootFolder.appendingPathComponent("BuildkiteTestCollector")
  }
}
