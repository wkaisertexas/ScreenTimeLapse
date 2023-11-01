import SwiftUI
import AVFoundation

var mainBody: RecordVideo?

@main
struct ScreenTimeLapseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @ObservedObject var recorderViewModel = RecorderViewModel()

    var body: some Scene {
        MenuBarExtra{
            ContentView().environmentObject(recorderViewModel)
        } label: {
            Text(verbatim: recorderViewModel.state.description)
        }.onChange(of: recorderViewModel.state){ _ in
            Task{
                await recorderViewModel.getDisplayInfo()
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the dock icon
        NSApp.setActivationPolicy(.accessory)
    }
}
