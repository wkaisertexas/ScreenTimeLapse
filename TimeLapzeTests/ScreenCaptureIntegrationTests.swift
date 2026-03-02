import ScreenCaptureKit
import XCTest

@testable import TimeLapze

@MainActor
final class ScreenCaptureIntegrationTests: XCTestCase {
  func testShareableContentLoads() async throws {
    try ScreenCaptureTestGate.requireAuthorized()

    let access = SystemScreenCaptureAccess()
    let content = try await access.fetchShareableContent()

    XCTAssertFalse(content.displays.isEmpty, "Expected at least one display.")
  }
}
