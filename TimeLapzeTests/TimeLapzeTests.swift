import AVFoundation
import XCTest

@testable import TimeLapze

final class TimeLapzeTests: XCTestCase {

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  func testValidFormats() throws {
    let baseConfig = VideoConfiguration()

    for config in baseConfig.validFormats {
      let typeDescription = baseConfig.convertFormatToString(config)
      let path = "testing\(typeDescription)"

      let url = URL(string: path, relativeTo: .temporaryDirectory)!
      let writer = try? AVAssetWriter(url: url, fileType: config)
    }
  }

  func testIsInTemporaryFolder() throws {
    let temporaryURL = URL(
      filePath: "test.txt", directoryHint: .notDirectory, relativeTo: .temporaryDirectory)

    XCTAssertTrue(temporaryURL.isInTemporaryFolder())
  }

  func testIsNotInTemporaryFolder() throws {
    let nonTemporaryURL = URL(
      filePath: "test.txt", directoryHint: .notDirectory, relativeTo: .desktopDirectory)

    XCTAssertFalse(nonTemporaryURL.isInTemporaryFolder())
  }

  func testPerformanceExample() throws {
    // This is an example of a performance test case.
    measure {
      // Put the code you want to measure the time of here.
    }
  }

}
