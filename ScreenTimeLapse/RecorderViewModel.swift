//
//  RecorderViewModel.swift
//  ScreenTimeLapse
//
//  Created by William Kaiser on 2/16/23.
//

import Foundation
import ScreenCaptureKit
import AVFoundation

// Has multiple recording sessions
class ScreenDisplayViewModel: ObservableObject{
    @Published var displays: [SCDisplay] = []
    @Published var apps: [SCRunningApplication] = []
    
    @Published var en_displays: [SCDisplay: Bool] = [:]
    @Published var en_apps: [SCRunningApplication: Bool] = [:]
    
    @Published var cameras: [AVCaptureDevice: Bool] = [:]
    
    // Recorders for the screen
    @Published var camera_recording: [AVCaptureDevice: Recorder] = [:]
    @Published var screen_recording: [SCDisplay: Recorder] = [:]
    
    @Published var content: SCShareableContent? = nil
    
    @MainActor
    func getDisplayInfo() async {
        do{
            let content: SCShareableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
            
            // Filters the current application (prevents overlay issues)
            self.apps = content.applications.filter{app in
                Bundle.main.bundleIdentifier != app.bundleIdentifier
            }
            self.displays = content.displays
            
            // Adds apps
            for app in self.apps{
                if !self.en_apps.contains(where: {app.isEqual(to: $0)}){
                    self.en_apps[app] = false // apps are disabled by default
                }
            }
            
            // Adds displays
            for display in self.displays{
                if !self.en_displays.contains(where: {display.isEqual(to: $0)}){
                    self.en_displays[display] = self.en_displays.count == 1 // enables the first display by default
                }
            }
            
            self.content = content
        }catch{
            print(error.localizedDescription)
        }
    }
    
    func getCameras(){
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: AVMediaType.video, position: .unspecified)
        
        // Sets the cameras dictionary
        for camera in discovery.devices{
            if !self.cameras.contains(where: {camera.isEqual(to: $0)}){
                self.cameras[camera] = false // cameras disabled by default
            }
        }
    }
    
    /// This functions inverts the `en_apps` list
    /// - Returns: The list of apps which should be disabled
    func getExcludedApps() -> [SCRunningApplication]{
        let apps =  en_apps.filter{elem in
            !elem.value
        }.map{elem in elem.key}
        return apps
    }
}
