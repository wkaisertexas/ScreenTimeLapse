import AVFoundation
import SwiftUI

/// Represents a user's preferences or settings
///
/// Has two main tabs:
/// - General Settings
/// - Video Settings
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
     }.navigationTitle("TimeLapze Settings")
      videoSettings().tabItem {
          Label("Video", systemImage: "video")
      }.navigationTitle("TimeLapze Settings")
      
    }
    .frame(width: 400)
    .fixedSize()
  }

  @ViewBuilder
  func generalSettings() -> some View {
    Form {
      Text("TimeLapze General Settings")
        .fontWeight(.medium)
        .font(.title)
    
        Divider()
        
      uiSettings()
    }
    .padding(10)
  }

  @ViewBuilder
  func videoSettings() -> some View {
    Form {
      Text("TimeLapze Video Settings")
        .fontWeight(.medium)
        .font(.title)
        
    Divider()
      playbackVideoSettings()
      captureVideoSettings()
      outputVideoSettings()
    }
    .padding(.bottom, 20)
    .padding(.top, 10)
    .padding(.leading, 20)
    .padding(.trailing, 20)
  }

  // MARK: Submenus
  @ViewBuilder
  func uiSettings() -> some View {

    Toggle("Hide icon in dock", isOn: $hideIcon).onChange(of: hideIcon) { hide in
      
    }
    Toggle("Show notifications", isOn: $showNotifications)
    Toggle("Show video after saving", isOn: $showAfterSave)

    HStack {
      Spacer()
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
    Text(
      "An hour long recording would be \(String(format: "%.1f", 60.0 / Double(timeMultiple))) minutes"
    )

    HStack {
      Text("\(String(format: "%.1f", timeMultiple))x faster")
      Slider(value: $timeMultiple, in: .init(uncheckedBounds: (1.0, 240.0)))
    }
    
    Divider()
      
    if #available(macOS 14.0, *) {
        Stepper(value: $framesPerSecond, in: 1...60, step: 1) {
          Text("Output FPS: \(framesPerSecond)")
        }.pickerStyle(.palette)
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
    .onChange(of: showPicker, perform: getDirectory)
      
      HStack{
          Text("Save videos to:")
          Text("\(saveLocation.path())").fontWeight(.medium)
      }
  }
    
 // MARK: Intents
    func getDirectory(newVal: Bool) {
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
}

#Preview {
    PreferencesView()
      .frame(width: 700, height: 300)
}
