import AVFoundation
import Foundation
import ScreenCaptureKit
import SwiftUI

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

  var description: LocalizedStringResource {
    switch self {
    case .low:
      return LocalizedStringResource("Low", comment: "low in terms of recording quality")
    case .medium:
      return LocalizedStringResource("Medium", comment: "medium in terms of recording quality")
    case .high:
      return LocalizedStringResource("High", comment: "high in terms of recording quality")
    }
  }
}

/// Preset date/time format options for the timestamp overlay
enum TimestampOverlayFormat: String, Codable, CaseIterable {
  case timeOnly = "HH:mm:ss"
  case dateOnly = "yyyy-MM-dd"
  case mediumDateTime = "MMM d, yyyy HH:mm:ss"
  case shortDateTime = "MM/dd/yy HH:mm"
  case fullDateTime = "EEEE, MMM d, yyyy 'at' HH:mm:ss"

  var description: String {
    switch self {
    case .timeOnly: return "Time only (14:30:00)"
    case .dateOnly: return "Date only (2026-02-05)"
    case .mediumDateTime: return "Date & time (Feb 5, 2026 14:30:00)"
    case .shortDateTime: return "Short (02/05/26 14:30)"
    case .fullDateTime: return "Full (Wednesday, Feb 5, 2026 at 14:30:00)"
    }
  }

  var dateFormat: String { rawValue }
}

/// Available fonts for timestamp overlay
enum TimestampFont: String, CaseIterable {
  case helvetica = "Helvetica"
  case helveticaNeue = "HelveticaNeue"
  case arial = "Arial"
  case sfPro = "SF Pro"
  case sfMono = "SF Mono"
  case menlo = "Menlo"
  case monaco = "Monaco"
  case courier = "Courier"
  case courierNew = "Courier New"
  case timesNewRoman = "Times New Roman"
  case georgia = "Georgia"
  case verdana = "Verdana"
  case futura = "Futura"
  case avenir = "Avenir"
  case avenirNext = "Avenir Next"

  var displayName: String {
    switch self {
    case .helvetica: return "Helvetica"
    case .helveticaNeue: return "Helvetica Neue"
    case .arial: return "Arial"
    case .sfPro: return "SF Pro"
    case .sfMono: return "SF Mono (monospace)"
    case .menlo: return "Menlo (monospace)"
    case .monaco: return "Monaco (monospace)"
    case .courier: return "Courier (monospace)"
    case .courierNew: return "Courier New (monospace)"
    case .timesNewRoman: return "Times New Roman"
    case .georgia: return "Georgia"
    case .verdana: return "Verdana"
    case .futura: return "Futura"
    case .avenir: return "Avenir"
    case .avenirNext: return "Avenir Next"
    }
  }
}

/// Allows sorting by `bundleIdentifier` so the displayed order is consistent
/// even when new `SCRunningApplication`s are added
extension SCRunningApplication: @retroactive Comparable {
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

// MARK: - Color hex for timestamp overlay settings
extension Color {
  /// Creates a Color from a hex string (e.g. "#FFFFFF" or "FFFFFF").
  init?(hex: String) {
    let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    guard s.count == 6 || s.count == 8,
      let value = UInt32(s, radix: 16)
    else { return nil }
    let r: Double
    let g: Double
    let b: Double
    let a: Double
    if s.count == 8 {
      r = Double((value >> 24) & 0xFF) / 255
      g = Double((value >> 16) & 0xFF) / 255
      b = Double((value >> 8) & 0xFF) / 255
      a = Double(value & 0xFF) / 255
    } else {
      r = Double((value >> 16) & 0xFF) / 255
      g = Double((value >> 8) & 0xFF) / 255
      b = Double(value & 0xFF) / 255
      a = 1.0
    }
    self.init(red: r, green: g, blue: b, opacity: a)
  }

  /// Returns a hex string (e.g. "#FFFFFF") for the color.
  func toHex() -> String {
    let nsColor = NSColor(self)
    let rgb = nsColor.usingColorSpace(.sRGB) ?? nsColor
    let r = Int(round(rgb.redComponent * 255))
    let g = Int(round(rgb.greenComponent * 255))
    let b = Int(round(rgb.blueComponent * 255))
    return String(format: "#%02X%02X%02X", r, g, b)
  }
}
