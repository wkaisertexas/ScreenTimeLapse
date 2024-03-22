import AVFoundation
import ScreenCaptureKit

/// Output information consists of details about each stream designed to be shared by a recorder view model
struct OutputInfo {
  var frameRate: Float = 25.0
  var timeDivisor: Float = 25.0

  /// Determines the time each frame should be shown on the screen
  func getFrameTime() -> Float { 1 / self.frameRate * self.timeDivisor }
}

/// Represents the possible states of the recording system
/// Converting into a string yields the app's icon
enum RecordingState: CustomStringConvertible {
  var description: String {
    switch self {
    case .stopped:
      return "record.circle.fill"
    case .paused:
      return "play.fill"
    case .recording:
      return "pause.fill"
    }
  }

  case stopped
  case recording
  case paused
}

/// Wraps the `SCStreamConfiguration.captureResolution` for user interface
enum QualitySettings: String, Codable, CaseIterable {
  case low
  case medium
  case high

  var description: String {
    switch self {
    case .low:
      return "Low"
    case .medium:
      return "Medium"
    case .high:
      return "High"
    }
  }
}

/// Allows sorting by `bundleIdentifier` so the displayed order is consistent
/// even when new `SCRunningApplication`s are added
extension SCRunningApplication: Comparable {
  public static func < (lhs: SCRunningApplication, rhs: SCRunningApplication) -> Bool {
    lhs.bundleIdentifier < rhs.bundleIdentifier
  }
}

/// Gets the App Version as a ``String``
extension Bundle {
    /// Fetches the current bundle version of the app.
    static var currentAppVersion: String? {
        #if os(macOS)
        let infoDictionaryKey = "CFBundleShortVersionString"
        #else
        let infoDictionaryKey = "CFBundleVersion"
        #endif
        
        return Bundle.main.object(forInfoDictionaryKey: infoDictionaryKey) as? String
    }
}
