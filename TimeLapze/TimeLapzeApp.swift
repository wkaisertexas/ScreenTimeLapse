import SwiftUI
import UserNotifications
import AVFoundation

@main
struct TimeLapzeApp: App {
    @NSApplicationDelegateAdaptor(ScreenTimeLapseAppDelegate.self) var appDelegate
    
    @ObservedObject var recorderViewModel = RecorderViewModel()
    
    var body: some Scene {
        MenuBarExtra{
            ContentView().environmentObject(recorderViewModel)
        } label: {
            Image(systemName: recorderViewModel.state.description).accessibilityLabel("ScreenTimeLapse MenuBar")
        }
        .onChange(of: recorderViewModel.state) { _ in
            Task{
                await recorderViewModel.getDisplayInfo()
            }
        }
        
        Settings{
            PreferencesView()
        }.windowResizability(.contentSize)
    }
}


/// General purpose `NSApplicationDelegate` and `UNUserNotificationCenterDelegate`
/// Abstracts away custom features unable to be set in `info.plist` or any other config files
class ScreenTimeLapseAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    /// Triggered when the application finished launcing and recieves a launch notification `Notification` on the event
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
        
        // Setting the notification delegate
        UNUserNotificationCenter.current().delegate = self
    }
   
    /// Handles when a user clicks on a notification uses the `response.notification.request.content.userInfo` to read attached data to open the `fileURL` key
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // opens the file just saved
        if let filePath = response.notification.request.content.userInfo["fileURL"] as? String, let fileURL = URL(string: filePath) {
            workspace.open(fileURL)
        }
        
        // completion handler things: `nil` in thsi case
        completionHandler()
    }
}
