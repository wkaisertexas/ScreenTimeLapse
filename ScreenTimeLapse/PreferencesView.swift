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
    
    @AppStorage("hideIcon") private var hideIcon : Bool = false
    
    @AppStorage("saveLocation") private var saveLocation : URL = FileManager.default.homeDirectoryForCurrentUser
    @State private var showPicker = false
    
    var body: some View {
        TabView{
            videoSettings().tabItem{
                Label("Preferences", systemImage: "gear")
            }
        }
        .padding(20)
    }
    
    @ViewBuilder
    func videoSettings() -> some View {
        Form {
            playbackVideoSettings()
            captureVideoSettings()
            outputVideoSettings()
        }
        .padding(20)
    }
    
    // MARK: Submenus
    @ViewBuilder
    func playbackVideoSettings() -> some View{
        Stepper(value: $framesPerSecond, in: 1...60, step: 1){
            Text("Output FPS \(framesPerSecond)")
        }
        
        Stepper(value: $timeMultiple, in: 1...60, step: 1){
            Text("Times faster \(timeMultiple) x")
        }
    }
    
    @ViewBuilder
    func captureVideoSettings() -> some View{
        Toggle("Hide Icon In Dock", isOn: $hideIcon)
        Toggle("Show notifications", isOn: $showNotifications)
        
        Picker("Quality", selection: $quality){
            ForEach(QualitySettings.allCases, id: \.self) { qualitySetting in
                Text(qualitySetting.description)
            }
        }.pickerStyle(SegmentedPickerStyle())
        
        Picker("Format", selection: $format){
            ForEach(baseConfig.validFormats, id: \.self){ format in
                Text(baseConfig.convertFormatToString(format))
            }
        }
    }
    
    @ViewBuilder
    func outputVideoSettings() -> some View{
        Button(action: {
            showPicker.toggle()
        }){
            Label("Choose Output Folder", systemImage: "folder")
        }
        .disabled(showPicker)
        .onChange(of: showPicker){ [ self ] in
            guard showPicker else { return }
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.begin { [ self ] res in
                showPicker = false
                guard res == .OK, let pickedURL = panel.url else { return }
                
                saveLocation = pickedURL
            }
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .frame(width: 500, height: 300)
    }
}

