import SwiftUI
import CoreData
import AVFoundation
import ScreenCaptureKit
import Foundation

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
        switch viewModel.state{
            case .stopped:
                startButton()
            case .recording:
                pauseButton()
                exitButton()
            case .paused:
                resumeButton()
                exitButton()
        }
    }
    
    // MARK: -Button View Builders
    
    @ViewBuilder
    func startButton() -> some View{
        Button("Start Recording"){
            viewModel.startRecording()
        }.keyboardShortcut("R").disabled(viewModel.recordersDisabled())
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
        appsMenu()
        Menu("Input Devices"){
            screensMenu()
            Divider()
            camerasMenu()
        }
    }
    
    @ViewBuilder
    func appsMenu() -> some View {
        Menu("Apps"){
            ForEach(viewModel.apps.keys.sorted(by: <), id: \.self){ app in
                Button(action: {
                    viewModel.apps[app]?.toggle()
                }){
                    HStack{
                        if viewModel.apps[app]!{
                            Image(systemName: "checkmark")
                        }
                        
                        Text(app.applicationName)
                    }
                }

            }
        }
    }
    
    @ViewBuilder
    func screensMenu() -> some View {
        ForEach(viewModel.screens, id: \.self)
            { screen in
                HStack{
                    screen.enabled ? Image(systemName: "checkmark") : nil
                    
                    Button(screen.description){
                        screen.enabled.toggle()
                    }
                }
            }
    }
    
    @ViewBuilder
    func camerasMenu() -> some View{
        ForEach(viewModel.cameras, id: \.self)
            { camera in
                HStack{
                    camera.enabled ? Image(systemName: "checkmark") : nil
                    
                    Button(camera.description){
                        camera.enabled.toggle()
                    }
                }
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
    
    var HELP: String = "https://google.com"
    var ABOUT: String = "https://apple.com"

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
