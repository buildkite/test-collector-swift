import Core

/// This function is automatically called by the Loader module to ensure the TestCollector is loaded before running any tests
@_cdecl("loadCollector")
public func loadCollector() {
  Core.TestCollector.load()
}
