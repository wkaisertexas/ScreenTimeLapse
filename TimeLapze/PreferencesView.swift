import AVFoundation
import AppKit
import SwiftUI

/// Represents a user's preferences or settings
///
/// Has two main tabs:
/// - General Settings
/// - Video Settings
struct PreferencesView: View {
  @EnvironmentObject private var preferencesViewModel: PreferencesViewModel

  var body: some View {
    TabView {
      generalSettings().tabItem {
        Label("General", systemImage: "gear")
      }.navigationTitle("TimeLapze Settings")
      videoSettings().tabItem {
        Label("Video", systemImage: "video")
      }.navigationTitle("TimeLapze Settings")
    }
    .frame(minWidth: 440, minHeight: 400)
    .background(VisualEffectView().ignoresSafeArea())
  }

  func generalSettings() -> some View {
    Form {
      Text("TimeLapze General Settings")
        .fontWeight(.semibold)
        .font(.headline)

      Spacer()

      uiSettings()
    }
    .padding(30)
  }

  func videoSettings() -> some View {
    ScrollView {
      Form {
        Text("TimeLapze Video Settings")
          .fontWeight(.semibold)
          .font(.headline)

        playbackVideoSettings()
        captureVideoSettings()
        timestampOverlaySettings()
        outputVideoSettings()
      }
      .padding(30)
    }
    .frame(minHeight: 400)
  }

  // MARK: Submenus
  @ViewBuilder
  func uiSettings() -> some View {
    Toggle("Show notifications", isOn: $preferencesViewModel.showNotifications)
    Toggle("Show video after saving", isOn: $preferencesViewModel.showAfterSave)

    Spacer()

    HStack {
      Link("About", destination: baseConfig.about)
      Link("Help", destination: baseConfig.help)

      Spacer()

      Button("Write Review") {
        ReviewManager.shared.getReview()
      }.buttonStyle(.borderedProminent)
    }
  }

  @ViewBuilder
  func playbackVideoSettings() -> some View {
    Text(
      "An hour long recording would be \(String(format: "%.1f", 60.0 / Double(preferencesViewModel.timeMultiple))) minutes"
    )

    HStack {
      TextField(
        "",
        value: Binding(
          get: { preferencesViewModel.timeMultiple },
          set: { preferencesViewModel.timeMultiple = min(max($0, 1.0), 240.0) }
        ),
        format: .number.precision(.fractionLength(1))
      )
      .textFieldStyle(.roundedBorder)
      .frame(width: 55)
      .multilineTextAlignment(.trailing)
      Text("x faster")
    }

    Slider(value: $preferencesViewModel.timeMultiple, in: 1.0...240.0)

    if #available(macOS 14.0, *) {
      Picker("Output FPS", selection: $preferencesViewModel.fpsDropdown) {
        ForEach(0..<preferencesViewModel.validFPS.count) { index in
          Text("\(preferencesViewModel.validFPS[index]) fps")
        }
      }.onChange(
        of: preferencesViewModel.fpsDropdown,
        { oldValue, newValue in
          preferencesViewModel.framesPerSecond = preferencesViewModel.validFPS[newValue]
        }
      )
      .pickerStyle(MenuPickerStyle())  // Style the picker as a dropdown menu
      .padding()

      if preferencesViewModel.fpsDropdown == preferencesViewModel.validFPS.count - 1 {
        Text("Want an even higher frame rate?")
        Stepper(value: $preferencesViewModel.framesPerSecond, in: 1...240, step: 1) {
          Text("Output FPS: \(preferencesViewModel.framesPerSecond)")
        }.pickerStyle(.segmented)
      }
    }
  }

  @ViewBuilder
  func captureVideoSettings() -> some View {
    if #available(macOS 14.0, *) {
      Picker("Quality", selection: $preferencesViewModel.quality) {
        ForEach(QualitySettings.allCases, id: \.self) { qualitySetting in
          Text(qualitySetting.description)
        }
      }.pickerStyle(SegmentedPickerStyle())
    }

    Picker("Format", selection: $preferencesViewModel.format) {
      ForEach(baseConfig.validFormats, id: \.self) { format in
        Text(baseConfig.convertFormatToString(format))
      }
    }
  }

  @ViewBuilder
  func timestampOverlaySettings() -> some View {
    // Camera timestamp settings
    Section {
      Toggle("Show on camera", isOn: $preferencesViewModel.cameraTimestampEnabled)

      Picker("Format", selection: $preferencesViewModel.cameraTimestampFormat) {
        ForEach(TimestampOverlayFormat.allCases, id: \.rawValue) { format in
          Text(format.description).tag(format.rawValue)
        }
      }
      .pickerStyle(.menu)
      .disabled(!preferencesViewModel.cameraTimestampEnabled)

      Picker("Font", selection: $preferencesViewModel.cameraTimestampFontName) {
        ForEach(TimestampFont.allCases, id: \.rawValue) { font in
          Text(font.displayName).tag(font.rawValue)
        }
      }
      .pickerStyle(.menu)
      .disabled(!preferencesViewModel.cameraTimestampEnabled)

      HStack {
        Text("Size: \(Int(preferencesViewModel.cameraTimestampFontSize)) pt")
        Slider(value: $preferencesViewModel.cameraTimestampFontSize, in: 10...72, step: 1)
          .disabled(!preferencesViewModel.cameraTimestampEnabled)
      }

      HStack {
        Text("Color")
        ColorPicker("", selection: Binding(
          get: { Color(hex: preferencesViewModel.cameraTimestampColorHex) ?? .white },
          set: { preferencesViewModel.cameraTimestampColorHex = $0.toHex() }
        ))
        .labelsHidden()
        .disabled(!preferencesViewModel.cameraTimestampEnabled)
      }
    } header: {
      Text("Camera timestamp")
    }

    // Screen timestamp settings
    Section {
      Toggle("Show on screen recording", isOn: $preferencesViewModel.screenTimestampEnabled)

      Picker("Format", selection: $preferencesViewModel.screenTimestampFormat) {
        ForEach(TimestampOverlayFormat.allCases, id: \.rawValue) { format in
          Text(format.description).tag(format.rawValue)
        }
      }
      .pickerStyle(.menu)
      .disabled(!preferencesViewModel.screenTimestampEnabled)

      Picker("Font", selection: $preferencesViewModel.screenTimestampFontName) {
        ForEach(TimestampFont.allCases, id: \.rawValue) { font in
          Text(font.displayName).tag(font.rawValue)
        }
      }
      .pickerStyle(.menu)
      .disabled(!preferencesViewModel.screenTimestampEnabled)

      HStack {
        Text("Size: \(Int(preferencesViewModel.screenTimestampFontSize)) pt")
        Slider(value: $preferencesViewModel.screenTimestampFontSize, in: 10...72, step: 1)
          .disabled(!preferencesViewModel.screenTimestampEnabled)
      }

      HStack {
        Text("Color")
        ColorPicker("", selection: Binding(
          get: { Color(hex: preferencesViewModel.screenTimestampColorHex) ?? .white },
          set: { preferencesViewModel.screenTimestampColorHex = $0.toHex() }
        ))
        .labelsHidden()
        .disabled(!preferencesViewModel.screenTimestampEnabled)
      }
    } header: {
      Text("Screen timestamp")
    } footer: {
      Text("Date and time appear in the top-right corner of recordings when enabled.")
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  @ViewBuilder
  func outputVideoSettings() -> some View {
    let chooseFolder = Button(action: {
      preferencesViewModel.showPicker.toggle()
    }) {
      Label("Choose Output Folder", systemImage: "folder")
    }
    .disabled(preferencesViewModel.showPicker)
    .onChange(of: preferencesViewModel.showPicker, perform: preferencesViewModel.getDirectory)

    // Subtle thing, but using bordered prominent to call attention to something when a default has not been set
    if preferencesViewModel.saveLocation.isInTemporaryFolder() {
      chooseFolder.buttonStyle(.borderedProminent)
    } else {
      chooseFolder
      HStack(alignment: .top) {
        Text("Save videos to:")
        Text(preferencesViewModel.saveLocation.path())
          .fontWeight(.medium)
          .lineLimit(1)
          .truncationMode(.middle)
      }
      HStack(spacing: 8) {
        Button(action: {
          NSWorkspace.shared.open(preferencesViewModel.saveLocation)
        }) {
          Label("Open in Finder", systemImage: "folder.badge.gearshape")
        }
        .help("Open the output folder in Finder")
        Button(action: {
          let path = preferencesViewModel.saveLocation.path()
          NSPasteboard.general.clearContents()
          NSPasteboard.general.setString(path, forType: .string)
        }) {
          Label("Copy path", systemImage: "doc.on.doc")
        }
        .help("Copy the folder path to the clipboard")
      }
    }
  }
}

/// The use of a ``VisualEffectView`` comes from Jack Waugh's [Creating a blurred window background with SwiftUI on macOS](https://zachwaugh.com/posts/swiftui-blurred-window-background-macos)
/// and is something that I think makes the preferences view look better
struct VisualEffectView: NSViewRepresentable {
  func makeNSView(context: Context) -> NSVisualEffectView {
    let effectView = NSVisualEffectView()
    effectView.state = .active
    return effectView
  }

  func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
  }
}

#Preview {
  PreferencesView()
    .frame(width: 700, height: 300)
}
