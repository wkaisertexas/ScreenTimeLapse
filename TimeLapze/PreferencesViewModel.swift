import AVFoundation
import SwiftUI


/// Manages data for the ``PreferencesView``
class PreferencesViewModel: ObservableObject {
    @AppStorage("showNotifications") var showNotifications = false
    @AppStorage("showAfterSave") var showAfterSave = false
    
    @AppStorage("framesPerSecond") var framesPerSecond = 30
    // Valid frames per second
    let validFPS = [10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
    
    @AppStorage("FPS") var fps: Double = 30.0
    @AppStorage("timeMultiple") var timeMultiple: Double = 5.0
    
    @AppStorage("quality") var quality: QualitySettings = .medium
    
    @AppStorage("format") var format: AVFileType = baseConfig.validFormats.first!
    
    @AppStorage("saveLocation") var saveLocation: URL = FileManager.default
        .homeDirectoryForCurrentUser
    @Published var showPicker = false
    @Published var FPSDropdown = 4
    @Published var FPSInput = ""
    
    @Environment(\.openURL) var openURL
    
    // MARK: Intents

    /// Gets the user to specify where they want to save output videos
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
