import AVFoundation
import CoreData
import ScreenCaptureKit
import SettingsAccess
import SwiftUI

/// Main menu-bar view of the application
struct ContentView: View {
  @EnvironmentObject private var viewModel: RecorderViewModel

  var body: some View {
    ActionButton()
    Divider()
    InputDevices()
    Divider()
    Info()
  }
}

/// A section which takes care of **start**, **pause**, **resume** and **exit**
struct ActionButton: View {
  @EnvironmentObject private var viewModel: RecorderViewModel

  @AppStorage("timeMultiple") private var timesFaster: Double?

  var body: some View {
    Section("\(String(format: "%.1f", timesFaster ?? 1.0))x faster recording") {
      switch viewModel.state {
      case .stopped:
        startButton()
      case .recording:
        pauseButton()
        exitButton()
      case .paused:
        resumeButton()
        exitButton()
      }
    }
  }

  // MARK: Buttons
  func startButton() -> some View {
    Button("Start Recording") {
      viewModel.startRecording()
    }
    .keyboardShortcut("R")
    .disabled(viewModel.recordersDisabled())
  }

  func pauseButton() -> some View {
    Button("Pause Recording") {
      viewModel.pauseRecording()
    }
    .keyboardShortcut("P")
    .disabled(viewModel.recordersDisabled())
  }

  func resumeButton() -> some View {
    Button("Resume Recording") {
      viewModel.resumeRecording()
    }
    .keyboardShortcut("R")
    .disabled(viewModel.recordersDisabled())
  }

  func exitButton() -> some View {
    Button("Exit and Save Recording") {
      viewModel.stopRecording()
    }
    .keyboardShortcut("S")
  }
}

/// Input devices of the project
struct InputDevices: View {
  @EnvironmentObject private var viewModel: RecorderViewModel

  var body: some View {
    appsMenu()
    Divider()
    screensMenu()
    camerasMenu()
  }

  // MARK: Sections

  /// Renders all the `SCRunningApplications` which can either be enabled or disabled
  func appsMenu() -> some View {
    Menu("Apps") {
      Section("Actions") {
        actionsMenu()
      }

      Section("Disabled") {
        ForEach(viewModel.excludedApps, id: \.self, content: app)
      }
      Section("Enabled") {
        ForEach(viewModel.includedApps, id: \.self, content: app)
      }
    }.pickerStyle(.menu)
  }

  /// Renders the `reset`, `invert` and `toggle` buttons
  @ViewBuilder
  func actionsMenu() -> some View {
    // Inverts enabled and disabled applications
    Button(action: {
      self.viewModel.invertApplications()
    }) {
      Image(systemName: "rectangle.2.swap")

      Text("Invert")
    }

    // Makes all applications enabled
    Button(action: {
      self.viewModel.resetApps()
    }) {
      Image(systemName: "clear")

      Text("Enable All")  // Calling it enable all instead of reset makes things a bit more clear
    }

    // Whether to show or hide the user's cursor
    Button(action: {
      viewModel.showCursor.toggle()
      viewModel.objectWillChange.send()
    }) {
      Image(systemName: viewModel.showCursor ? "cursorarrow.rays" : "cursorarrow")
      Text(viewModel.showCursor ? "Hide Cursor" : "Show Cursor")
    }
  }

  /// Renders all available `Screen` objects as an interactable list
  func screensMenu() -> some View {
    viewModel.screens.isEmpty
      ? nil
      : Section("Screens") {
        ForEach(viewModel.screens, id: \.self, content: screen)
      }
  }

  /// Renders all avaible `Camera` objects as an interactable list
  func camerasMenu() -> some View {
    viewModel.cameras.isEmpty
      ? nil
      : Section("Cameras") {
        ForEach(viewModel.cameras, id: \.self, content: camera)
      }
  }

  // MARK: Components
  /// Renders a single `Screen` as a button with either an enabled or disabled checkmark
  func screen(_ screen: Screen) -> some View {
    Button(action: { viewModel.toggleScreen(screen: screen) }) {
      screen.enabled ? Image(systemName: "checkmark") : nil

      Text(screen.description)
    }
  }

  /// Renders a single `Camera` as a button with either an enabled or disabled checkmark
  func camera(_ camera: Camera) -> some View {
    Button(action: {
      viewModel.toggleCamera(camera: camera)
    }) {
      camera.enabled ? Image(systemName: "checkmark") : nil

      Text(camera.description)
    }
  }

  /// Renders  single `SCRunningApplication` as either enabled or disabled
  ///
  /// Gets the application's icon based on the process id
  @ViewBuilder
  func app(_ app: SCRunningApplication) -> some View {
    if let runningApp = NSRunningApplication(processIdentifier: app.processID),
      runningApp.activationPolicy == .regular, let appIcon = runningApp.icon
    {
      Button(action: {
        viewModel.toggleApp(app: app)
      }) {
        Image(nsImage: appIcon)
        Text(app.applicationName)
      }
    }
  }
}

/// Random `Info` about the project
/// (Settings and Quit Button)
struct Info: View {
  @Environment(\.openURL) var openURL

  var body: some View {
    if #available(macOS 14.0, *) {
      SettingsLink()
        .keyboardShortcut(",")
    } else {
      // SettingsLink from the orchetect/SettingsAccess package
      SettingsLink {
        Text("Settings..")
      } preAction: {
        // nothing for now
      } postAction: {
        // nothing for now
      }.keyboardShortcut(",")
    }
    Divider()

    Button("Quit") {
      NSApplication.shared.terminate(nil)
    }.keyboardShortcut("q")
  }
}
