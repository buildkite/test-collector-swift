import Core

// MARK: - Deprecated after 0.3.0

extension TestCollector {
  /// Annotates the current test.
  ///
  /// The provided content is added to the collected span data and will appear in the span timeline.
  ///
  /// - Parameter content: The content of this annotation
  @available(*, deprecated, message: "'annotate' is no longer supported")
  public static func annotate(_ content: @autoclosure () -> String) {
    Core.TestCollector.shared?.annotate(content())
  }
}
