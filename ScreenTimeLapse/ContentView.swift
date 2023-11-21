import SwiftUI
import CoreData
import AVFoundation
import ScreenCaptureKit

struct ContentView: View {
    @EnvironmentObject private var viewModel: RecorderViewModel
    
    var body: some View {
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
                ForEach(viewModel.excludedApps, id: \.self, content: app)
            }
            Section("Enabled"){
                ForEach(viewModel.includedApps, id: \.self, content: app)
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
        if let runningApp = NSRunningApplication(processIdentifier: app.processID), runningApp.activationPolicy == .regular, let appIcon = runningApp.icon {
            Button(action: {
                viewModel.toggleApp(app: app)
            }){
                Image(nsImage: appIcon)
                Text(app.applicationName)
            }
        }
    }
}

/// Random info about the project
struct Info: View{
    @Environment(\.openURL) var openURL
    
    var body: some View{
        if #available(macOS 14.0, *) {
            SettingsLink()
                .keyboardShortcut(",")
            Divider()
        }
        Button("About"){
            if let url = URL(string: baseConfig.ABOUT) {
                openURL(url)
            }
        }
        Button("Help"){
            if let url = URL(string: baseConfig.HELP) {
                openURL(url)
            }
        }
        Divider()
        Button("Quit"){
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }
}

