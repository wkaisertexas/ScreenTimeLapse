import Foundation
import SettingsAccess
import SwiftUI

/// The onboarding model for ``OnboardingView``
class OnboardingViewModel: ObservableObject {
  // Environments
  @Environment(\.openWindow) private var openWindow

  // App Storage
  @AppStorage("shown") var onboarding: Bool = false
  @AppStorage("onboarded") var onboarded: Bool = false

  // General State
  @Published var onWindow: OnboardingWindows = .introPage
  @Published var dropdownShown: Bool = false
  @Published var settingsShown: Bool = false
  @Published var startRecordingShown: Bool = false

  // MARK: Intents
  func skipOnboarding() {
    onboarded = true
  }

  /// Skips to the next window and updates ``onWindow``
  func nextWindow() {
    switch onWindow {
    case .introPage:
      dropdownShown = true
      openMenuBar()
    default:
      break
    }

    // updates the value
    onWindow = onWindow.next()
  }

  /// Goes to the previous window and updates ``onWindow``
  func previousWindow() {
    onWindow = onWindow.prev()
  }

  // MARK: Properties
  var hasNext: Bool {
    onWindow.hasNext
  }

  var hasPrev: Bool {
    onWindow.hasPrev
  }

  // MARK: HELPERS

  /// Programatically opens the ``MenuBarExtra`` for more interactive onboarding
  func openMenuBar() {
    let windows = NSApp.windows

    // we are going to get the second app
    let secondApp = windows.last!

    let statusItem = secondApp.value(forKey: "statusItem") as? NSStatusItem
    statusItem?.button?.performClick(nil)
  }
}
