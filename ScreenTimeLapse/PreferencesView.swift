//
//  PreferencesView.swift
//  ScreenTimeLapse
//
//  Created by William Kaiser on 10/31/23.
//

import SwiftUI
import AVFoundation

// TODO: Probably move this into a seperate file
enum QualitySettings: CustomStringConvertible, CaseIterable {
    case low
    case medium
    case high
    
    var description: String {
        switch self {
            case .low:
                return "Low"
            case .medium:
                return "Medium"
            case .high:
                return "High"
        }
    }
}

//let VALIDFORMATS: [] = []

struct PreferencesView: View {
    @AppStorage("showNotifications") private var showNotifications = false
    
    @AppStorage("framesPerSecond") private var framesPerSecond = 30
    @AppStorage("timeMultiple") private var timeMultiple = 5
    
    @State private var quality : QualitySettings = .medium
    
    var body: some View {
        TabView{
            videoSettings()
        }
    }
    
    @ViewBuilder
    func videoSettings() -> some View {
        Form {
            Section(header: Text("Playback")) {
                Stepper(value: $framesPerSecond, in: 1...60, step: 1){
                    Text("Output Frames per Seconds (FPS): \(framesPerSecond)")
                }
                
                Stepper(value: $timeMultiple, in: 1...60, step: 1){
                    Text("How much faster than realtime: \(timeMultiple) x")
                }
                
            }
            Section(header: Text("Capture")){
                Toggle("Show notifications", isOn: $showNotifications)
                
                Picker("Quality", selection: $quality){
                    ForEach(QualitySettings.allCases, id: \.self) {  qualitySetting in
                        Text(qualitySetting.description)
                    }
                }.pickerStyle(SegmentedPickerStyle())
            }
        }.tabItem{
            Label("Preferences", systemImage: "hand.raised")
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}

