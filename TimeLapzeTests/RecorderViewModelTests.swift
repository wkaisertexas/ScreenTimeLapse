import AVFoundation
import ScreenCaptureKit
import XCTest

@testable import TimeLapze

/// Testing the ``RecorderViewModel``
final class RecorderViewModelTests: XCTestCase {
  // If a device is connected, then cameras should empty
  func testDeviceConnectedNotification() throws {
    let viewModel = RecorderViewModel()
    let expectation = XCTestExpectation(description: "Device connected should refresh camera list.")

    NotificationCenter.default.post(name: .AVCaptureDeviceWasConnected, object: nil)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      XCTAssertFalse(
        viewModel.cameras.isEmpty,
        "Cameras should not be empty after device connection notification.")
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1)
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
