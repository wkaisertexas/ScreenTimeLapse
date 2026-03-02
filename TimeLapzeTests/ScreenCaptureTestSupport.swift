import CoreGraphics
import Security
import XCTest

enum ScreenCaptureEntitlementError: Error, CustomStringConvertible {
  case missing([String])

  var description: String {
    switch self {
    case .missing(let keys):
      return "Missing required entitlements: \(keys.joined(separator: ", "))"
    }
  }
}

enum ScreenCaptureEntitlementChecker {
  static let requiredEntitlements = ["com.apple.security.screen-recording"]

  static func missingEntitlements() -> [String] {
    guard let task = SecTaskCreateFromSelf(nil) else {
      return requiredEntitlements
    }

    return requiredEntitlements.filter { key in
      let value = SecTaskCopyValueForEntitlement(task, key as CFString, nil)
      if let boolValue = value as? Bool {
        return boolValue == false
      }
      if let numberValue = value as? NSNumber {
        return numberValue.boolValue == false
      }
      return true
    }
  }
}

enum ScreenCaptureTestGate {
  static func requireAuthorized(
    file: StaticString = #filePath,
    line: UInt = #line
  ) throws {
    guard ProcessInfo.processInfo.environment["RUN_SCREEN_CAPTURE_TESTS"] == "1" else {
      throw XCTSkip("Screen capture tests are disabled. Set RUN_SCREEN_CAPTURE_TESTS=1.")
    }

    let missing = ScreenCaptureEntitlementChecker.missingEntitlements()
    if !missing.isEmpty {
      XCTFail(
        "Screen capture tests require entitlements. Missing: \(missing.joined(separator: ", "))",
        file: file,
        line: line
      )
      throw ScreenCaptureEntitlementError.missing(missing)
    }

    guard CGPreflightScreenCaptureAccess() else {
      throw XCTSkip("Screen recording permission not granted for the test runner.")
    }
  }
}
