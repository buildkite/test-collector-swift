@testable import Core
import XCTest

class AnyCodableTests: XCTestCase {
  func testDecoding() throws {
    let decoder = JSONDecoder()

    let input = #"""
    {
      "bool": true,
      "int": 7,
      "double": 42.42,
      "string": "Blob",
      "array": ["A", "B", "C"],
      "dictionary": {
        "0": "foo",
        "1": "bar"
      }
    }
    """#.data(using: .utf8)!

    let output = try decoder.decode([String: AnyCodable].self, from: input)

    XCTAssertEqual(output["bool"]?.base as? Bool, true)
    XCTAssertEqual(output["int"]?.base as? Int, 7)
    XCTAssertEqual(output["double"]?.base as? Double, 42.42)
    XCTAssertEqual(output["string"]?.base as? String, "Blob")
    XCTAssertEqual(output["array"]?.base as? [String], ["A", "B", "C"])
    XCTAssertEqual(output["dictionary"]?.base as? [String: String], ["0": "foo", "1": "bar"])

    XCTAssertEqual(
      output,
      [
        "bool": true,
        "int": 7,
        "double": 42.42,
        "string": "Blob",
        "array": ["A", "B", "C"],
        "dictionary": ["0": "foo", "1": "bar"],
      ]
    )
  }

  func testEncoding() throws {
    let encoder = JSONEncoder()

    let input: [String: AnyCodable] = [
      "bool": true,
      "int": 7,
      "double": 42.42,
      "string": "Blob",
      "array": ["A", "B", "C"],
      "dictionary": ["0": "foo", "1": "bar"],
    ]

    let data = try encoder.encode(input)
    let output = try JSONSerialization.jsonObject(with: data, options: [])

    XCTAssertEqual(
      output as? NSDictionary,
      [
        "bool": true,
        "int": 7,
        "double": 42.42,
        "string": "Blob",
        "array": ["A", "B", "C"],
        "dictionary": ["0": "foo", "1": "bar"],
      ]
    )
  }
}
