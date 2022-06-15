import Foundation

extension Trace {
  /// A type containing information for a timed block of work.
  struct Span: Equatable {
    /// The type of span. Used for categorising spans.
    var section: String

    /// A monotonic timestamp in seconds for when the span started.
    var startAt: TimeInterval?

    /// A monotonic timestamp in seconds for when the span ended.
    var endAt: TimeInterval?

    /// The number of seconds that elapsed during this span.
    var duration: TimeInterval?

    /// Any information related to this span.
    var detail: [String: String] = [:]

    /// Any spans that occurred during this span.
    var children: [Span] = []
  }
}

extension Trace.Span: Encodable {
  enum CodingKeys: String, CodingKey {
    case section
    case startAt = "start_at"
    case endAt = "end_at"
    case duration
    case detail
    case children
  }
}
