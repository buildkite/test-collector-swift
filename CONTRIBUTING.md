# Contributing to the Swift Test Collector

## 💡 Bug Reports, Feature Requests and Questions

Before submitting a new GitHub issue, please make sure to:

- Read the [README][readme] for this repo.
- Read other documentation in this repo.
- Search the [existing issues][issues] for similar issues.

If the above doesn't help, please [submit an issue][new-issue] via GitHub.

## 💻 Contributing Code

### Checking out the Code

- Click the [Fork][fork-repo] button in the upper right corner of the repository.
- Clone your fork:
    `git clone git@github.com:<YOUR_GITHUB_USER>/test-collector-swift.git`
- See the [GitHub documentation][fork-docs] about managing your fork.

### Recommended

- Create a new branch to work on with `git checkout -b <YOUR_BRANCH_NAME>`.
    - Branch names should be descriptive of what you're working on, eg: `docs/updating-contributing-guide`, `fix/create-user-crash`.
- Use [good descriptive commit messages][commit-messages] when committing code.

## ✅ Testing

- If your code contains feature changes, please write unit tests for those changes.
- Run the unit tests in Xcode before submitting your Pull Request.

## ⬆️ Submitting a Pull Request

When you are ready to submit the PR, everything you need to know about submitting the PR itself is inside our [Pull Request Template][pr-template]. Some best practices are:

- Use a descriptive title.
- Link the issues that are related to your PR in the body.

## 🔎 After the review

Once a Code Owner has reviewed your PR, you might need to make changes before it gets merged. To make it easier on us, please make sure to avoid amending commits or force pushing to your branch to make corrections. By avoiding rewriting the commit history, you will allow each round of edits to become its own visible commit. This helps the people who need to review your code easily understand exactly what has changed since the last time they looked.

When you are done addressing your review, make sure you alert the reviewer in a comment or via GitHub's re-request review command. See [GitHub's documentation for dealing with Pull Requests][pr-docs].

After your contribution is merged, users can access it immediately by pointing to the main branch; otherwise, your changes will be included in the next release.

## 🤝 Code of Conduct

Help us keep this project diverse, open and inclusive. Please read and follow our [Code of Conduct][code-of-conduct].

## 🙏 Thanks for Contributing!

Thank you for taking the time to contribute to the project!

## 📜 License

This project is licensed as per the [LICENSE][license] file.

All contributions to this project are also under this license as per [GitHub's Terms of Service][github-terms-contribution].

<!-- Links: -->
[code-of-conduct]: CODE_OF_CONDUCT.md
[commit-messages]: https://chris.beams.io/posts/git-commit
[fork-docs]: https://help.github.com/articles/working-with-forks
[fork-repo]: https://github.com/buildkite/test-collector-swift/fork
[github-terms-contribution]: https://help.github.com/en/github/site-policy/github-terms-of-service#6-contributions-under-repository-license
[issues]: https://github.com/buildkite/test-collector-swift/issues
[license]: LICENSE
[new-issue]: https://github.com/buildkite/test-collector-swift/issues/new/choose
[pr-docs]: https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/requesting-a-pull-request-review
[pr-template]: .github/PULL_REQUEST_TEMPLATE.md
[readme]: README.md