import AVFoundation
import XCTest

@testable import TimeLapze

final class RecorderViewModelTests: XCTestCase {

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  /// Tests to make sure the view model transitions are logical
  ///
  /// Seems redundant, but this actually caught a bug earlier
  func testRecorderViewModelStateTransitions() throws {
    let viewModel = RecorderViewModel()

    viewModel.state = .stopped
    XCTAssertEqual(viewModel.state, .stopped)

    viewModel.startRecording()
    XCTAssertEqual(viewModel.state, .recording)

    viewModel.pauseRecording()
    XCTAssertEqual(viewModel.state, .paused)

    viewModel.saveRecordings()
    XCTAssertEqual(viewModel.state, .stopped)
  }

  /// If a format is valid, you should be able to create an ``AVAssertWriter`` with that format
  func testValidFormats() throws {
    let baseConfig = VideoConfiguration()

    for config in baseConfig.validFormats {
      let typeDescription = baseConfig.convertFormatToString(config)
      let path = "testing\(typeDescription)"

      let url = URL(string: path, relativeTo: .temporaryDirectory)!
      let writer = try? AVAssetWriter(url: url, fileType: config)
    }
  }

  /// Tests a helper made for URLs to check if they were generated in a temporay folder
  func testIsInTemporaryFolder() throws {
    let temporaryURL = URL(
      filePath: "test.txt", directoryHint: .notDirectory, relativeTo: .temporaryDirectory)

    XCTAssertTrue(temporaryURL.isInTemporaryFolder())
  }

  /// Tests a helper made to check if they were generated not in a temporary folder
  func testIsNotInTemporaryFolder() throws {
    let nonTemporaryURL = URL(
      filePath: "test.txt", directoryHint: .notDirectory, relativeTo: .desktopDirectory)

    XCTAssertFalse(nonTemporaryURL.isInTemporaryFolder())
  }

}
