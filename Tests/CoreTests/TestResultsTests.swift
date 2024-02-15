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
            ],
            location: .init(
              filePath: "/foo/bar",
              line: 10
            )
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
        .init(compactDescription: "First failure", description: "Failure 1", sourceCodeContext: .init(
          location: .init(
            filePath: "/foo/first",
            line: 50
          )
        )),
        .init(compactDescription: "Second failure", description: "Failure 2", sourceCodeContext: .init(
          location: .init(
            filePath: "/foo/second",
            line: 60
          )
        )),
        .init(compactDescription: "Third failure", description: "Failure 3", sourceCodeContext: .init(
          location: .init(
            filePath: "/foo/third",
            line: 70
          )
        )),
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
          NSDictionary(
            dictionary: [
              "id": "00000000-0000-0000-0000-000000000000",
              "scope": "TestResultsTests",
              "name": "testSuccess",
              "result": "passed",
              "failure_expanded": NSArray(),
              "history": NSDictionary(
                dictionary: [
                  "section": "span0",
                  "detail": NSDictionary(),
                  "children": NSArray(),
                ]
              ),
            ]
          ),
          [
            "id": "00000000-0000-0000-0000-000000000001",
            "scope": "TestResultsTests",
            "location": "/foo/bar:10",
            "file_name": "/foo/bar",
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
            "history": NSDictionary(
              dictionary: [
                "section": "span1",
                "detail": NSDictionary(),
                "children": NSArray(),
              ]
            ),
          ],
          [
            "id": "00000000-0000-0000-0000-000000000002",
            "scope": "TestResultsTests",
            "location": "/foo/first:50",
            "file_name": "/foo/first",
            "name": "testMultipleFailures",
            "result": "failed",
            "failure_reason": "3 failures: First failure, Second failure, Third failure",
            "failure_expanded": [
              ["backtrace": NSArray(), "expanded": ["Failure 1"]],
              ["backtrace": NSArray(), "expanded": ["Failure 2"]],
              ["backtrace": NSArray(), "expanded": ["Failure 3"]],
            ],
            "history": NSDictionary(
              dictionary: [
                "section": "span2",
                "detail": NSDictionary(),
                "children": NSArray(),
              ]
            ),
          ],
        ],
      ]
    )
  }
}
