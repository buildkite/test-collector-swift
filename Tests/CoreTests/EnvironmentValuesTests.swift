@testable import Core
import XCTest

final class EnvironmentValuesTests: XCTestCase {
  func testValueDefinitionPrecedence() {
    let values = ["ONE": "VALUES"]
    let processEnvironment = ["ONE": "ENVIRONMENT", "TWO": "ENVIRONMENT"]
    let infoPlist = ["ONE": "INFO PLIST", "TWO": "INFO PLIST", "THREE": "INFO PLIST"]
    let environment = EnvironmentValues(
      values: values,
      getFromEnvironment: { processEnvironment[$0] },
      getFromInfoDictionary: { infoPlist[$0] }
    )
    XCTAssertNil(environment.string(for: "ZERO"))
    XCTAssertEqual(environment.string(for: "ONE"), "VALUES")
    XCTAssertEqual(environment.string(for: "TWO"), "ENVIRONMENT")
    XCTAssertEqual(environment.string(for: "THREE"), "INFO PLIST")
  }

  func testTrimsValues() {
    let values = ["ONE": "ONE   "]
    let processEnvironment = ["TWO": "   TWO   "]
    let infoPlist = ["THREE": "   THREE"]
    let environment = EnvironmentValues(
      values: values,
      getFromEnvironment: { processEnvironment[$0] },
      getFromInfoDictionary: { infoPlist[$0] }
    )
    XCTAssertEqual(environment.string(for: "ONE"), "ONE")
    XCTAssertEqual(environment.string(for: "TWO"), "TWO")
    XCTAssertEqual(environment.string(for: "THREE"), "THREE")
  }

  func testIgnoresEmptyValues() {
    let values = ["NOTHING": ""]
    let processEnvironment = ["NOTHING": "       "]
    let infoPlist = ["NOTHING": "   \n   "]
    let environment = EnvironmentValues(
      values: values,
      getFromEnvironment: { processEnvironment[$0] },
      getFromInfoDictionary: { infoPlist[$0] }
    )
    XCTAssertEqual(environment.string(for: "NOTHING"), nil)
  }

  func testURL() {
    let processEnvironment = ["TEST_URL": "https://api.test.com/"]
    let environment = EnvironmentValues(getFromEnvironment: { processEnvironment[$0] })
    XCTAssertEqual(environment.url(for: "TEST_URL"), URL(string: "https://api.test.com/")!)
  }
}
