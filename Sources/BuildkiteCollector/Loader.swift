import Core

/// This function is automatically called by the Loader module to ensure the Collector is loaded before running any tests
@_cdecl("loadCollector")
public func loadCollector() {
  Core.Collector.load()
}
