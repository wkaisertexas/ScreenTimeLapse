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
    // Valid frames per second
    private let validFPS = [10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    
    @AppStorage("FPS") private var fps: Double = 30.0
    @AppStorage("timeMultiple") private var timeMultiple: Double = 5.0
    
    @AppStorage("quality") var quality: QualitySettings = .medium
    
    @AppStorage("format") private var format: AVFileType = baseConfig.validFormats.first!
    
    @AppStorage("saveLocation") private var saveLocation: URL = FileManager.default
        .homeDirectoryForCurrentUser
    @State private var showPicker = false
    @State private var FPSDropdown = 4
    @State private var FPSInput = ""
    
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
        .frame(width: 450)
        .fixedSize()
    }
    
    @ViewBuilder
    func generalSettings() -> some View {
        Form {
            Text("TimeLapze General Settings")
                .fontWeight(.semibold)
                .font(.headline)
            
            Divider()
            
            uiSettings()
        }
        .padding(20)
    }
    
    @ViewBuilder
    func videoSettings() -> some View {
        Form {
            Text("TimeLapze Video Settings")
                .fontWeight(.semibold)
                .font(.headline)
            
            Divider()
            playbackVideoSettings()
            captureVideoSettings()
            outputVideoSettings()
        }
        .padding(30)
    }
    
    // MARK: Submenus
    @ViewBuilder
    func uiSettings() -> some View {
        Toggle("Show notifications", isOn: $showNotifications)
        Toggle("Show video after saving", isOn: $showAfterSave)
        
        Divider()
        
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
            
            Spacer()

            Button("Write Review") {
                reviewManager.getReview()
            }.buttonStyle(.borderedProminent)
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
            
            Picker("Output FPS", selection: $FPSDropdown) {
                ForEach(0..<validFPS.count) { index  in
                    Text("\(validFPS[index]) fps")
                }
            }.onChange(of: FPSDropdown, { oldValue, newValue in
                framesPerSecond = validFPS[newValue]
            })
            .pickerStyle(MenuPickerStyle()) // Style the picker as a dropdown menu
            .padding()
            
            if FPSDropdown == validFPS.count - 1 {
                Text("Want an even higher frame rate?")
                Stepper(value: $framesPerSecond, in: 1...240, step: 1) {
                    Text("Output FPS: \(framesPerSecond)")
                }.pickerStyle(.segmented)
                
//                TextField("Enter your FPS", value: $FPSInput, formatter: NumberFormatter())
//                                .padding()
//                                .textFieldStyle(RoundedBorderTextFieldStyle())
//                                .onChange(of: FPSInput) { oldValue, newValue in
//                                    if let number = Int(newValue) {
//                                        if (1...240).contains(number) {
//                                            framesPerSecond = number
//                                        }
//                                    }
//                                }
            }
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
        let chooseFolder = Button(action: {
            showPicker.toggle()
        }) {
            Label("Choose Output Folder", systemImage: "folder")
        }
        .disabled(showPicker)
        .onChange(of: showPicker, perform: getDirectory)
        
        // Subtle thing, but using bordered prominent to call attention to something when a default has not been set
        if saveLocation.hasDirectoryPath {
            chooseFolder
            HStack{
                Text("Save videos to:")
                Text("\(saveLocation.path())").fontWeight(.medium)
            }
        } else {
            chooseFolder.buttonStyle(.borderedProminent)
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
