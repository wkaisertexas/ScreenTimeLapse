import AVFoundation
import SwiftUI

struct PreferencesView: View {
  @AppStorage("showNotifications") private var showNotifications = false
  @AppStorage("showAfterSave") private var showAfterSave = false

  @AppStorage("framesPerSecond") private var framesPerSecond = 30
  @AppStorage("FPS") private var fps: Double = 30.0
  @AppStorage("timeMultiple") private var timeMultiple: Double = 5.0

  @AppStorage("quality") var quality: QualitySettings = .medium

  @AppStorage("format") private var format: AVFileType = baseConfig.validFormats.first!

  @AppStorage("hideIcon") private var hideIcon: Bool = false

  @AppStorage("saveLocation") private var saveLocation: URL = FileManager.default
    .homeDirectoryForCurrentUser
  @State private var showPicker = false

  @Environment(\.openURL) var openURL

  var body: some View {
    TabView {
      generalSettings().tabItem {
        Label("General", systemImage: "gear")
      }
      videoSettings().tabItem {
        Label("Video", systemImage: "video")
      }
    }
    .padding(20)
  }

  @ViewBuilder
  func generalSettings() -> some View {
    Form {
      Text("TimeLapze General Settings")
        .fontWeight(.bold)

      uiSettings()
    }
    .padding(20)
  }

  @ViewBuilder
  func videoSettings() -> some View {
    Form {
      Text("TimeLapze Video Settings")
        .fontWeight(.bold)

      playbackVideoSettings()
      captureVideoSettings()
      outputVideoSettings()
    }
    .padding(20)
  }

  // MARK: Submenus
  @ViewBuilder
  func uiSettings() -> some View {
    Toggle("Hide icon in dock", isOn: $hideIcon).onChange(of: hideIcon) { hide in
      if hide {
        NSApp.setActivationPolicy(.accessory)
      } else {
        NSApp.setActivationPolicy(.regular)
      }
    }
    Toggle("Show notifications", isOn: $showNotifications)
    Toggle("Show video after saving", isOn: $showAfterSave)

    HStack {
      Button("About") {
        if let url = URL(string: baseConfig.ABOUT) {
          openURL(url)
        }
      }

      Button("Help") {
        if let url = URL(string: baseConfig.HELP) {
          openURL(url)
        }
      }
    }
  }

  @ViewBuilder
  func playbackVideoSettings() -> some View {
    if #available(macOS 14.0, *) {
      Stepper(value: $framesPerSecond, in: 1...60, step: 1) {
        Text("Output FPS: \(framesPerSecond)")
      }.pickerStyle(.palette)
    }
    //        Slider(value: $framesPerSecond, in: 1...60)
    //        Slider(value: $fps, in: .init(uncheckedBounds: (1.0, 60.0)))

    Text(
      "An hour long recording would be \(String(format: "%.1f", 60.0 / Double(timeMultiple))) minutes"
    )

    HStack {
      Text("\(String(format: "%.1f", timeMultiple))x faster")
      Slider(value: $timeMultiple, in: .init(uncheckedBounds: (1.0, 240.0)))
    }
  }

  @ViewBuilder
  func captureVideoSettings() -> some View {
    if #available(macOS 14.0, *) {
      Picker("Quality", selection: $quality) {
        ForEach(QualitySettings.allCases, id: \.self) { qualitySetting in
          Text(qualitySetting.description)
        }
      }.pickerStyle(SegmentedPickerStyle())
    }

    Picker("Format", selection: $format) {
      ForEach(baseConfig.validFormats, id: \.self) { format in
        Text(baseConfig.convertFormatToString(format))
      }
    }
  }

  @ViewBuilder
  func outputVideoSettings() -> some View {
    Button(action: {
      showPicker.toggle()
    }) {
      Label("Choose Output Folder", systemImage: "folder")
    }
    .disabled(showPicker)
    .onChange(of: showPicker) { _ in
      guard showPicker else { return }
      let panel = NSOpenPanel()
      panel.allowsMultipleSelection = false
      panel.canChooseDirectories = true
      panel.canChooseFiles = false
      panel.begin { [self] res in
        showPicker = false
        guard res == .OK, let pickedURL = panel.url else { return }

        saveLocation = pickedURL
      }
    }

    Text("Save videos to \(saveLocation.path())")
  }
}

struct PreferencesView_Previews: PreviewProvider {
  static var previews: some View {
    PreferencesView()
      .frame(width: 700, height: 300)
  }
}
