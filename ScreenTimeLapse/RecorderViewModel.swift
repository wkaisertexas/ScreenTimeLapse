import Foundation
import ScreenCaptureKit
import AVFoundation


class RecorderViewModel: ObservableObject{
    @Published var displays: [SCDisplay] = []
    @Published var apps: [SCRunningApplication] = []
    
    @Published var en_displays: [SCDisplay: Bool] = [:]
    @Published var en_apps: [SCRunningApplication: Bool] = [:]
    
    @Published var cameras: [AVCaptureDevice: Bool] = [:]
    
    // Recorders for the screen
    @Published var camera_recording: [AVCaptureDevice: Recorder] = [:]
    @Published var screen_recording: [SCDisplay: Recorder] = [:]
    
    @Published var content: SCShareableContent? = nil
    @Published var state: state = .stopped
    @Published var showCursor: Bool = false
    
    @MainActor
    func getDisplayInfo() async {
        do{
            let content: SCShareableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            
            // Apps
            self.apps = content.applications.filter{app in
                Bundle.main.bundleIdentifier != app.bundleIdentifier
            }
            
            for app in self.apps{
                if self.en_apps.contains(where: {app.isNotEqual(to: $0)}){
                    self.en_apps[app] = false // apps are disabled by default
                }
            }
            
            // Displays
            self.displays = content.displays
            self.displays = self.displays.sorted{ first, second in first.displayID > second.displayID}
            for display in self.displays{
                if self.en_displays.contains(where: {display.isNotEqual(to: $0)}){
                    self.en_displays[display] = false
                }
            }
            
            if let first = self.displays.first{
                self.en_displays[first] = true
            }
            
            self.content = content
        }catch{
            print(error.localizedDescription)
        }
    }
    
    func getCameras(){
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: AVMediaType.video, position: .unspecified)
        
        for camera in discovery.devices{
            if !self.cameras.contains(where: {camera.isEqual(to: $0)}){ // new cameras
                self.cameras[camera] = false // cameras disabled by default
            }
        }
    }
    
    /// This functions inverts the `en_apps` list
    /// - Returns: The list of apps which should be disabled
    func getExcludedApps() -> [SCRunningApplication]{
        return self.en_apps.filter{elem in
            !elem.value
        }.map{elem in elem.key}
    }
    
    
    // MARK: - Recording
    func startRecording(){
        self.cameras.filter{camera in
            camera.value
        }.map{$0.key}.forEach{ camera in

        }
        
        self.en_displays.filter{screen in
            screen.value
        }.map{$0.key}.forEach(recordScreen)
    }
    
    func pauseRecording(){
        
    }
    
    func resumeRecording(){
        
    }
    
    func stopRecording(){
        
    }
    
    // Mark: - Intents
    func getState() -> String{
        return "🦆"
    }
    
    /// All cameras connected to the computer
    private func getCameras() -> [AVCaptureDevice]{
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: AVMediaType.video, position: .unspecified)
        return discovery.devices
    }
}
