import SwiftUI
import UserNotifications
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
    }
}

class ScreenTimeLapseAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the dock icon
        if UserDefaults.standard.bool(forKey: "hideIcon") {
            NSApp.setActivationPolicy(.accessory)
        }
        
        // Notifications
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                logger.log("Authorized notification settings")
            case .denied:
                logger.log("Denied notification settings")
            case .provisional:
                logger.log("Provisional notifications present")
            case .notDetermined:
                logger.log("Requesting Notification Permissions")
                
                let center = UNUserNotificationCenter.current()
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        logger.log("Permissions granted")
                    } else {
                        logger.error("Permissions denined")
                    }
                }
            @unknown default:
                logger.error("Unknown default")
            }
        }
    }
}
