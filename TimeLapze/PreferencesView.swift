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
    .frame(width: 450)
    .fixedSize()
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
    Form {
      Text("TimeLapze Video Settings")
        .fontWeight(.semibold)
        .font(.headline)

      playbackVideoSettings()
      captureVideoSettings()
      outputVideoSettings()
    }
    .padding(30)
  }

  // MARK: Submenus
  @ViewBuilder
  func uiSettings() -> some View {
    Toggle("Show notifications", isOn: $preferencesViewModel.showNotifications)
    Toggle("Show video after saving", isOn: $preferencesViewModel.showAfterSave)

    Spacer()

    HStack {
      Link("About", destination: baseConfig.ABOUT)
      Link("Help", destination: baseConfig.HELP)

      Spacer()

      Button("Write Review") {
        reviewManager.getReview()
      }.buttonStyle(.borderedProminent)
    }
  }

  @ViewBuilder
  func playbackVideoSettings() -> some View {
    Text(
      "An hour long recording would be \(String(format: "%.1f", 60.0 / Double(preferencesViewModel.timeMultiple))) minutes"
    )

    HStack {
      Text("\(String(format: "%.1f", preferencesViewModel.timeMultiple))x faster")
      Slider(value: $preferencesViewModel.timeMultiple, in: .init(uncheckedBounds: (1.0, 240.0)))
    }

    if #available(macOS 14.0, *) {
      Picker("Output FPS", selection: $preferencesViewModel.FPSDropdown) {
        ForEach(0..<preferencesViewModel.validFPS.count) { index in
          Text("\(preferencesViewModel.validFPS[index]) fps")
        }
      }.onChange(
        of: preferencesViewModel.FPSDropdown,
        { oldValue, newValue in
          preferencesViewModel.framesPerSecond = preferencesViewModel.validFPS[newValue]
        }
      )
      .pickerStyle(MenuPickerStyle())  // Style the picker as a dropdown menu
      .padding()

      if preferencesViewModel.FPSDropdown == preferencesViewModel.validFPS.count - 1 {
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
      HStack {
        Text("Save videos to:")
        Text("\(preferencesViewModel.saveLocation.path())").fontWeight(.medium)
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
