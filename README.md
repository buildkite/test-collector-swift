# SwiftPM release mirror

This repository is the generated release mirror for Swift Package Manager.
Existing consumers keep using this repository and its plain `vX.Y.Z` tags;
new tags are generated at release time from
[`test-collector-swift/`](https://github.com/buildkite/bktest/tree/main/test-collector-swift)
in the [buildkite/bktest](https://github.com/buildkite/bktest) monorepo.

Development, issues, and pull requests all happen in
[buildkite/bktest](https://github.com/buildkite/bktest). This default branch
remains a pointer; only release tags are machine-written here. Historic tags,
commits, issues, and pull requests remain browsable.
