import Core

/// This function is automatically called by the Loader module to ensure the test collector is loaded before running any tests
@_cdecl("loadCollector")
@usableFromInline
func loadCollector() {
  Core.TestCollector.load()
}
