import AVFoundation
import SwiftUI


/// Manages data for the ``PreferencesView``
class PreferencesViewManager: ObservableObject {
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
}
