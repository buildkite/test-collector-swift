import Foundation

extension Tracer {
  /// Constructs a "live" tracer that uses the system uptime for the start and end time of spans.
  ///
  /// - Parameters:
  ///   - systemUptime: A closure that returns the system uptime.
  ///   - spanId: A closure that returns a unique identifier.
  /// - Returns: A tracer that use the system uptime for span times.
  static func live(
    systemUptime: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime },
    spanId: @escaping () -> AnyHashable = { UUID() }
  ) -> Tracer {
    var stack: [(id: AnyHashable, span: Trace.Span)] = []

    return Tracer(
      startSpan: { section, detail in
        let id = spanId()
        let span = Trace.Span(section: section, startAt: systemUptime(), detail: detail)
        stack.append((id, span))
        return id

      },
      endSpan: { id in
        assert(!stack.isEmpty, "No active spans")
        assert(stack.last!.id == id, "Id does not match current span")

        var span = stack.last!.span
        let endAt = systemUptime()

        span.endAt = endAt
        span.duration = span.startAt.map { endAt - $0 }
        stack.removeLast()

        if !stack.isEmpty {
          stack[stack.endIndex - 1].span.children.append(span)
        }

        return span
      }
    )
  }
}
