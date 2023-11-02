//
//  PreferencesView.swift
//  ScreenTimeLapse
//
//  Created by William Kaiser on 10/31/23.
//

import SwiftUI
import AVFoundation

struct PreferencesView: View {
    @AppStorage("showNotifications") private var showNotifications = false
    
    @AppStorage("framesPerSecond") private var framesPerSecond = 30
    @AppStorage("timeMultiple") private var timeMultiple = 5
    
    @AppStorage("quality") var quality : QualitySettings = .medium
    
    @AppStorage("format") private var format : AVFileType = baseConfig.validFormats.first!
    
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
                
                Picker("Format", selection: $format){
                    ForEach(baseConfig.validFormats, id: \.self){ format in
                        Text(baseConfig.convertFormatToString(format))
                    }
                }
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

