import Foundation
import ScreenCaptureKit
import AVFoundation

/// Represents a syncronized session of `Recordable` objects
class RecorderViewModel: ObservableObject{
    @Published var apps: [SCRunningApplication : Bool] = [:]
    @Published var content: SCShareableContent? = nil
    
    @Published var cameras: [Camera] = []
    @Published var screens: [Screen] = []
    
    @Published var state: State = .stopped
    @Published var showCursor: Bool = false
    
    @MainActor
    func getDisplayInfo() async {
        do{
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            
            self.apps = convertApps(apps: content.applications)
            self.screens = convertDisplays(displays: content.displays)
            
            self.content = content
        }catch{
            print(error.localizedDescription)
        }
    }
    
    func getCameras(){
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: AVMediaType.video, position: .unspecified)
        
        self.cameras = convertCameras(camera: discovery.devices)
    }
    
    /// This functions inverts the `self.apps` list
    /// - Returns: The list of apps which should be disabled
    func getExcludedApps() -> [SCRunningApplication]{
        return self.apps.filter{elem in
            !elem.value
        }.map{elem in elem.key}
    }
    
    // MARK: - Recording
    func startRecording(){
        self.cameras.indices
            .forEach{ index in
                cameras[index].startRecording()
            }
        
        self.screens.indices
            .forEach{ index in
                screens[index].startRecording()
            }
    }
    
    func pauseRecording(){
        self.cameras.indices
            .forEach{ index in
                cameras[index].pauseRecording()
            }
        
        self.screens.indices
            .forEach{ index in
                screens[index].pauseRecording()
            }
    }
    
    func resumeRecording(){
        self.cameras.indices
            .forEach{ index in
                cameras[index].resumeRecording()
            }
        
        self.screens.indices
            .forEach{ index in
                screens[index].resumeRecording()
            }
    }
    
    func stopRecording(){
        self.cameras.indices
            .forEach{ index in
                cameras[index].stopRecording()
            }
        
        self.screens.indices
            .forEach{ index in
                screens[index].stopRecording()
            }
    }
    
    func saveRecordings(){
        self.cameras.indices
            .forEach{ index in
                cameras[index].saveRecording()
            }
        
        self.screens.indices
            .forEach{ index in
                screens[index].saveRecording()
            }
    }
    
    // Mark: - Intents
    func getState() -> String{
        switch state{
        case .stopped:
            return "🎥"
        case .paused:
            return "▶️"
        case .recording:
            return "⏸️"
        }
    }
    
    /// Gets apps from content and converts this into a dictioanry
    private func convertApps(apps input: [SCRunningApplication]) -> [SCRunningApplication : Bool]{
        let returnApps = input
            .filter{app in
                Bundle.main.bundleIdentifier != app.bundleIdentifier
            }
            .map{ app in
                (app, self.apps[app] ?? true)
            }
        
        return Dictionary(uniqueKeysWithValues: returnApps)
    }
    
    /// Turns an array of SCDisplays into new screens
    private func convertDisplays(displays input: [SCDisplay]) -> [Screen]{
        var newScreens = input
            .filter{ display in
                self.screens.contains{recorder in
                    recorder.screen != display
            }}
            .map(getScreenRecorder)
        
        for screen in self.screens{
            newScreens.append(screen)
        }
        
        newScreens = newScreens
            .sorted{ (first, second) in
                first.screen.displayID < second.screen.displayID
            }
        
        if self.screens.isEmpty, !newScreens.isEmpty{
            newScreens.first!.enabled = true
        }
        
        return newScreens
    }
    
    /// Converts an array of cameras from a Discovery session into cameras
    private func convertCameras(camera input: [AVCaptureDevice]) -> [Camera]{
        var newCameras = input
            .filter{ camera in
                self.cameras.contains{ recorder in
                    recorder.inputDevice != camera
                }
            }.map(getCameraRecorder)
        
        for camera in self.cameras{
            newCameras.append(camera)
        }
        
        newCameras = newCameras
            .sorted{ (first, second) in
                first.inputDevice.uniqueID < second.inputDevice.uniqueID
            }
        
        return newCameras
    }
    
    
    /// All cameras connected to the computer
    private func getCameras() -> [AVCaptureDevice]{
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: AVMediaType.video, position: .unspecified)
        return discovery.devices
    }
    
    // MARK: -Recorder Creation
    
    /// Generates the default settings for a screen recorder
    private func getScreenRecorder(_ screen: SCDisplay) -> Screen{
        Screen(screen: screen, showCursor: showCursor)
    }
    
    /// Generates the deafault settings for a camera reocrder
    private func getCameraRecorder(_ camera: AVCaptureDevice) -> Camera{
        Camera(camera: camera)
    }
}
