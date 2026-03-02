import CoreGraphics
import ScreenCaptureKit

protocol ScreenCaptureAccessing {
  func preflight() -> Bool
  @discardableResult func request() -> Bool
  func fetchShareableContent() async throws -> SCShareableContent
}

struct SystemScreenCaptureAccess: ScreenCaptureAccessing {
  func preflight() -> Bool {
    CGPreflightScreenCaptureAccess()
  }

  @discardableResult
  func request() -> Bool {
    CGRequestScreenCaptureAccess()
    return CGPreflightScreenCaptureAccess()
  }

  func fetchShareableContent() async throws -> SCShareableContent {
    try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
  }
}

enum ScreenCaptureAccessError: Error {
  case unavailable
}

struct NoOpScreenCaptureAccess: ScreenCaptureAccessing {
  func preflight() -> Bool {
    false
  }

  @discardableResult
  func request() -> Bool {
    false
  }

  func fetchShareableContent() async throws -> SCShareableContent {
    throw ScreenCaptureAccessError.unavailable
  }
}
