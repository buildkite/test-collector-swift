import Foundation

/// A type for capturing spans over time.
struct Tracer {
  private var startSpan: (String, [String: String]) -> AnyHashable
  private var endSpan: (AnyHashable) -> Trace.Span

  init(
    startSpan: @escaping (String, [String: String]) -> AnyHashable,
    endSpan: @escaping (AnyHashable) -> Trace.Span
  ) {
    self.startSpan = startSpan
    self.endSpan = endSpan
  }

  /// Starts recording a span.
  ///
  /// - Parameters:
  ///   - section: The section's name.
  ///   - detail: Information attached to the span.
  /// - Returns: The identifier associated with the started span.
  func startSpan(section: String, detail: [String: String] = [:]) -> AnyHashable {
    self.startSpan(section, detail)
  }

  /// Ends the span that corresponds to the specified id.
  ///
  /// - Parameter id: The span's identifier.
  /// - Returns: The completed span.
  func endSpan(id: AnyHashable) -> Trace.Span {
    self.endSpan(id)
  }

  /// Adds an annotation span as a child to the current span .
  ///
  /// - Parameter content: The annotation's content.
  func annotate(_ content: String) {
    let id = self.startSpan(section: "annotation", detail: ["content": content])
    _ = self.endSpan(id: id)
  }
}
