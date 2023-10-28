import SwiftUI
import CoreData
import AVFoundation
import ScreenCaptureKit

struct ContentView: View {
    @EnvironmentObject private var viewModel: RecorderViewModel
        
    var body: some View {
        // Button which is clicked
        Button("Start recording"){
//            mainBody = RecordVideo()
        }
        
        ActionButton()
        Divider()
        InputDevices()
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
        }
        .keyboardShortcut("R")
        .disabled(viewModel.recordersDisabled())
    }
    
    @ViewBuilder
    func pauseButton() -> some View{
        Button("Pause Recording"){
            viewModel.pauseRecording()
        }
        .keyboardShortcut("P")
        .disabled(viewModel.recordersDisabled())
    }
    
    @ViewBuilder
    func resumeButton() -> some View{
        Button("Resume Recording"){
            viewModel.resumeRecording()
        }
        .keyboardShortcut("R")
        .disabled(viewModel.recordersDisabled())
    }
    
    @ViewBuilder
    func exitButton() -> some View{
        Button("Exit Recording"){
            viewModel.stopRecording()
        }
        .keyboardShortcut("S")
    }
}

/// Input devices of the project
struct InputDevices: View{
    @EnvironmentObject private var viewModel: RecorderViewModel

    var body: some View{
        appsMenu().pickerStyle(.menu)
        Divider()
        
        screensMenu()
        camerasMenu()
    }
    
    // MARK: -Sections
    
    /// Renders all the `SCRunningApplications` which can either be enabled or disabled
    @ViewBuilder
    func appsMenu() -> some View {
        Menu("Apps"){
            Section("Actions"){
                actionsMenu()
            }
            
            Section("Disabled"){
                ForEach(viewModel.apps.keys.filter{!viewModel.apps[$0]!}.sorted(by: <), id: \.self, content: app)
            }
            Section("Enabled"){
                ForEach(viewModel.apps.keys.filter{viewModel.apps[$0]!}.sorted(by: <), id: \.self, content: app)
            }
        }
    }
    
    /// Renders the `reset`, `invert` and `toggle` buttons
    @ViewBuilder
    func actionsMenu() -> some View{
        Button(action: {
            self.viewModel.refreshApps()
        }){
            Image(systemName: "arrow.clockwise")
            
            Text("Refresh")
        }
        
        Button(action:{
            self.viewModel.invertApplications()
        }){
            Image(systemName: "rectangle.2.swap")
            
            Text("Invert")
        }
        
        Button(action: {
            self.viewModel.resetApps()
        }){
            Image(systemName: "clear")
            
            Text("Reset")
        }
        
        Button(action: {
            viewModel.showCursor.toggle()
            viewModel.objectWillChange.send()
        }){
            Image(systemName: viewModel.showCursor ? "cursorarrow.rays" : "cursorarrow")
            Text(viewModel.showCursor ? "Hide Cursor": "Show Cursor")
        }
    }
    
    /// Renders all available `Screen` objects as an interactable list
    @ViewBuilder
    func screensMenu() -> some View {
        viewModel.screens.isEmpty ? nil :
        Section("Screens"){
            ForEach(viewModel.screens, id: \.self, content: screen)
        }
    }
    
    /// Renders all avaible `Camera` objects as an interactable list
    @ViewBuilder
    func camerasMenu() -> some View{
        viewModel.cameras.isEmpty ? nil :
        Section("Cameras"){
            ForEach(viewModel.cameras, id: \.self, content: camera)
        }
    }
    
    // MARK: -Components
    /// Renders a single `Screen` as a button with either an enabled or disabled checkmark
    @ViewBuilder
    func screen(_ screen: Screen) -> some View{
        Button(action: {viewModel.toggleScreen(screen: screen)}){
            screen.enabled ? Image(systemName: "checkmark") : nil
                
            Text(screen.description)
        }
    }
    
    /// Renders a single `Camera` as a button with either an enabled or disabled checkmark
    @ViewBuilder
    func camera(_ camera: Camera) -> some View{
        Button(action: {
            viewModel.toggleCameras(camera: camera)
        }){
            camera.enabled ? Image(systemName: "checkmark") : nil
                
            Text(camera.description)
        }
    }
    
    /// Renders  single `SCRunningApplication` as either enabled or disabled
    @ViewBuilder
    func app(_ app: SCRunningApplication) -> some View{
        Button(action: {
            viewModel.toggleApp(app: app)
        }){
            if let runningApp = NSRunningApplication(processIdentifier: app.processID), let appIcon = runningApp.icon {
                Image(nsImage: appIcon)
                Text(app.applicationName)
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

struct Prefrences: View{
    // TODO: Replace these with actual values later
    @State var showCursor: Bool = false
    @State var frameRate: Double = 25.0
    @State var timeMultiple: Double = 3.0
    var body: some View{
        Form{
            Section(header: Text("View Info")){
                Toggle("Show Cursor", isOn: $showCursor)
                
                Slider(value: $frameRate, in: 0...100, step: 1.0)
                Slider(value: $frameRate, in: 0...100, step: 1.0)
                Slider(value: $frameRate, in: 0...100, step: 1.0)
            }
        }
    }
}

struct SettingsPreview: PreviewProvider {
    static var previews: some View{
        Prefrences()
    }
}
