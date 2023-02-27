//
//  ContentView.swift
//  ScreenTimeLapse
//
//  Created by William Kaiser on 1/1/23.
//

import SwiftUI
import CoreData
import AVFoundation
import ScreenCaptureKit
import Foundation

// Properties
let HELP = "https://apple.com"
let ABOUT = "https://apple.com"


struct ContentView: View {
    @EnvironmentObject private var viewModel: RecorderViewModel
    
    var body: some View {
        ActionButton()
        Divider()
        InputDevices()
        HStack{
            if viewModel.showCursor{
                Image(systemName: "checkmark")
            }
            
            Button(viewModel.showCursor ? "Hide Cursor": "Show Cursor"){
                viewModel.showCursor.toggle()
            }
        }
        
        Divider()
        Info()
    }
}

/// A pause / record button for the user
struct ActionButton: View{
    @EnvironmentObject private var viewModel: RecorderViewModel
    
    var body: some View{
        Picker("Testing", selection: $viewModel.state){
            startButton().tag(RecordingState.stopped)
            pauseButton().tag(RecordingState.recording)
            resumeButton().tag(RecordingState.paused)
            exitButton().tag(RecordingState.recording).tag(RecordingState.paused)
        }
//        switch $viewModel.state{
//            case RecordingState.stopped:
//                startButton()
//            case .recording:
//                pauseButton()
//                exitButton()
//            case .paused:
//                resumeButton()
//                exitButton()
//        }
    }
    
    // MARK: -Button View Builders
    
    @ViewBuilder
    func startButton() -> some View{
        Button("Start Recording"){
            viewModel.startRecording()
        }.keyboardShortcut("R")
    }
    
    @ViewBuilder
    func pauseButton() -> some View{
        Button("Pause Recording"){
            viewModel.pauseRecording()
        }.keyboardShortcut("P")
    }
    
    @ViewBuilder
    func resumeButton() -> some View{
        Button("Resume Recording"){
            viewModel.resumeRecording()
        }.keyboardShortcut("R")
    }
    
    @ViewBuilder
    func exitButton() -> some View{
        Button("Exit Recording"){
            viewModel.stopRecording()
        }.keyboardShortcut("S")
    }
}
/// Input devices of the project
struct InputDevices: View{
    @EnvironmentObject private var viewModel: RecorderViewModel

    var body: some View{
        Menu("Input Devices"){
//                ForEach(viewModel.apps, id: \.self){app in
//                    Button(action: {
//                        viewModel.en_apps[app]?.toggle()
//                    }){
//                        HStack{
//                            if viewModel.en_apps[app]!{
//                                Image(systemName: "checkmark")
//                            }
//
//                            Text(app.applicationName)
//                        }
//                    }
//                }
//
//            viewModel.displays.isEmpty ? nil : Divider()
//
//            ForEach(viewModel.displays, id: \.self){display in
//                    HStack{
//                        if viewModel.en_displays[display]! {
//                            Image(systemName: "checkmark")
//                        }
//                        Button("(\(display.width) x \(display.height)) Display # \(display.displayID)"){
//                            viewModel.en_displays[display]?.toggle()
//                        }
//                    }
//                }
            
            
            Divider()
            
//            ForEach($viewModel.cameras.keys){camera in
//                HStack{
//                    if viewModel.cameras[camera]!{
//                        Image(systemName: "checkmark")
//                    }
//                    
//                    Button(camera.localizedName){
//                        viewModel.cameras[camera]?.toggle()
//                    }
//                }
//            }
            
        }

    }
}

/// Recording property modifying alerts
/// Determines the viewmodel's `frameRate` and `timeDivisor`
struct PropertyModifiers: View{
    @EnvironmentObject private var viewModel: RecorderViewModel
    
    @State private var fr_alert = false
    @State private var su_alert = false
    
    var body: some View{
        frameRateAdjust()
        speedMultipleAdjust()
    }
    
    @ViewBuilder
    func frameRateAdjust() -> some View {
//        Button(String(format: "( %.1f ) Adjust frame rate", frame_rate)){
//            fr_alert = true
//        }.alert("Change frame rate", isPresented: $fr_alert, actions: {
//            TextField("Frame rate", value: $frame_rate, format: .number)
//        }, message: {
//            TextField("Frame rate", value: $frame_rate, format: .number)
//        })
    }
    
    @ViewBuilder
    func speedMultipleAdjust() -> some View {
//        Button(String(format: "( %.1fx ) Adjust speed multiple", speed_up)){
//            su_alert.toggle()
//        }.sheet(isPresented: $su_alert){
//            TextField("This is where you input the number", value: $frame_rate, format: .number)
//        }
    }
    
    let speed_formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
}

/// Random info about the project
struct Info: View{
    @Environment(\.openURL) var openURL

    var body: some View{
        Button("Help"){
            openURL(URL(string: HELP)!)
        }
        Button("About"){
            openURL(URL(string: ABOUT)!)
        }
        Button("Quit"){
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }
}
