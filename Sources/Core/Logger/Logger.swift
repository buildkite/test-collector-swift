import Dispatch
import Foundation

struct Logger {
  /// The log level.
  var logLevel: Level

  private var printer: (String) -> Void

  private let queue: DispatchQueue
  private let loggerTasks = DispatchGroup()

  /// Constructs a new logger
  ///
  /// If messages a logged with a level less than the provided `logLevel`, they will be ignored.
  ///
  /// - Parameters:
  ///   - logLevel: The log level for this logger
  ///   - log: A closure that is called when this logger logs a message
  ///   - queue: A closure that is called when this logger logs a message
  init(
    logLevel: Logger.Level = .info,
    printer: @escaping (String) -> Void = loggerPrint,
    queue: DispatchQueue = loggerQueue
  ) {
    self.logLevel = logLevel
    self.printer = printer
    self.queue = queue
  }

  /// Log a message at the specified log level
  ///
  /// If the logger's `logLevel` is greater than the specified `level`, nothing will be logged.
  ///
  /// - Parameters:
  ///   - level: The log level for the following message.
  ///   - message: The message to be logged.
  func log(level: Level, _ message: @autoclosure () -> String) {
    guard level >= self.logLevel else { return }
    let message = "[BuildkiteTestCollector] \(level): \(message())"
    self.queue.async(group: self.loggerTasks) {
      self.printer(message)
    }
  }

  /// Log a message with the `debug` log level
  ///
  /// If the logger's `logLevel` is greater than `debug`, nothing will be logged.
  ///
  /// - Parameter message: The message to be logged.
  func debug(_ message: @autoclosure () -> String) {
    self.log(level: .debug, message())
  }

  /// Log a message with the `info` log level
  ///
  /// If the logger's `logLevel` is greater than `info`, nothing will be logged.
  ///
  /// - Parameter message: The message to be logged.
  func info(_ message: @autoclosure () -> String) {
    self.log(level: .info, message())
  }

  /// Log a message with the `error` log level
  ///
  /// If the logger's `logLevel` is greater than `error`, nothing will be logged.
  ///
  /// - Parameter message: The message to be logged.
  func error(_ message: @autoclosure () -> String) {
    self.log(level: .error, message())
  }

  /// Waits synchronously for the previously submitted logs to complete.
  ///
  /// - Parameter timeout: The maximum duration in seconds to wait for logs to complete.
  func waitForLogs(timeout: TimeInterval = tenSeconds) {
    let result = self.loggerTasks.yieldAndWait(timeout: timeout)
    if result == .timedOut {
      self.error("Logger timed out before logging all messages")
    }
  }
}

extension Logger {
  /// The log level.
  ///
  /// Ordered from least to most severe.
  enum Level: String, Comparable {
    case debug
    case info
    case error

    // Based on values from https://github.com/apple/swift-log
    var orderingValue: UInt8 {
      switch self {
      case .debug: return 1
      case .info: return 2
      case .error: return 5
      }
    }

    static func < (lhs: Logger.Level, rhs: Logger.Level) -> Bool {
      lhs.orderingValue < rhs.orderingValue
    }
  }
}

// Default timeout used by waitForLogs
private let tenSeconds: TimeInterval = 10

// Default queue used by Logger
private let loggerQueue = DispatchQueue(
  label: "com.buildkite.collector-swift.logger",
  qos: .background
)

// Default printer used by Logger
private func loggerPrint(_ message: String) {
  // While loading, print to stderr to avoid conflicting with `swift test --list-tests`
  if TestCollector.shared == nil {
    fputs("\(message)\n", stderr)
  } else {
    print(message)
  }
}
