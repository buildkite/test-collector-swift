@testable import Core
import XCTest

final class TestResultsTests: XCTestCase {
  func testJSONEncoding() throws {
    let testSuccess = TestState(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
      className: "TestResultsTests",
      testName: "testSuccess",
      result: .passed,
      issues: [],
      expectedFailures: []
    )

    let testFailure = TestState(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
      className: "TestResultsTests",
      testName: "testFailure",
      result: .failed,
      issues: [
        .init(
          compactDescription: "The test failed",
          description: """
          The thing you expected to happen didn't happen.
          I wish I could provide you with more information.
          """,
          sourceCodeContext: .init(
            callStack: [
              .init(
                address: 1,
                symbolInfo: .init(
                  imageName: "Library",
                  symbolName: "Foo.bar()"
                )
              ),
              .init(
                address: 0,
                symbolInfo: .init(
                  imageName: "CoreTests",
                  symbolName: "TestResultsTests.testJSONEncoding()"
                )
              ),
            ]
          )
        ),
      ],
      expectedFailures: []
    )

    let testMultipleFailures = TestState(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
      className: "TestResultsTests",
      testName: "testMultipleFailures",
      result: .failed,
      issues: [
        .init(compactDescription: "First failure", description: "Failure 1", sourceCodeContext: .init()),
        .init(compactDescription: "Second failure", description: "Failure 2", sourceCodeContext: .init()),
        .init(compactDescription: "Third failure", description: "Failure 3", sourceCodeContext: .init()),
      ],
      expectedFailures: []
    )

    let testResults = TestResults.json(
      runEnv: RunEnvironment(key: "test"),
      data: [
        .init(test: testSuccess, span: .init(section: "span0")),
        .init(test: testFailure, span: .init(section: "span1")),
        .init(test: testMultipleFailures, span: .init(section: "span2")),
      ]
    )

    let data = try JSONEncoder().encode(testResults)

    let json = try JSONSerialization.jsonObject(with: data)

    XCTAssertEqual(
      json as? NSDictionary,
      [
        "format": "json",
        "run_env": ["key": "test"],
        "data": [
          [
            "id": "00000000-0000-0000-0000-000000000000",
            "scope": "TestResultsTests",
            "name": "testSuccess",
            "result": "passed",
            "failure_expanded": NSArray(),
            "history": [
              "section": "span0",
              "detail": NSDictionary(),
              "children": NSArray(),
            ] as NSDictionary,
          ] as NSDictionary,
          [
            "id": "00000000-0000-0000-0000-000000000001",
            "scope": "TestResultsTests",
            "name": "testFailure",
            "result": "failed",
            "failure_reason": "The test failed",
            "failure_expanded": [
              [
                "backtrace": [
                  "0 Foo.bar()",
                  "1 TestResultsTests.testJSONEncoding()",
                ],
                "expanded": [
                  "The thing you expected to happen didn't happen.",
                  "I wish I could provide you with more information.",
                ],
              ],
            ],
            "history": [
              "section": "span1",
              "detail": NSDictionary(),
              "children": NSArray(),
            ] as NSDictionary,
          ],
          [
            "id": "00000000-0000-0000-0000-000000000002",
            "scope": "TestResultsTests",
            "name": "testMultipleFailures",
            "result": "failed",
            "failure_reason": "3 failures: First failure, Second failure, Third failure",
            "failure_expanded": [
              ["backtrace": NSArray(), "expanded": ["Failure 1"]],
              ["backtrace": NSArray(), "expanded": ["Failure 2"]],
              ["backtrace": NSArray(), "expanded": ["Failure 3"]],
            ],
            "history": [
              "section": "span2",
              "detail": NSDictionary(),
              "children": NSArray(),
            ] as NSDictionary,
          ],
        ],
      ]
    )
  }
}
