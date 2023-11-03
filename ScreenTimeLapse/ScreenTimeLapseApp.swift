import SwiftUI
import AVFoundation

@main
struct ScreenTimeLapseApp: App {
    @NSApplicationDelegateAdaptor(ScreenTimeLapseAppDelegate.self) var appDelegate

    @ObservedObject var recorderViewModel = RecorderViewModel()

    var body: some Scene {
        MenuBarExtra{
            ContentView().environmentObject(recorderViewModel)
        } label: {
            Text(verbatim: recorderViewModel.state.description)
        }
        .onChange(of: recorderViewModel.state) {
            Task{
                await recorderViewModel.getDisplayInfo()
            }
        }
        
        Settings{
            PreferencesView()
        }
        .defaultSize( .init(width: 450, height: 200))
    }
}

class ScreenTimeLapseAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the dock icon
        if UserDefaults.standard.bool(forKey: "hideIcon") {
            NSApp.setActivationPolicy(.accessory) 
        }
    }
}
