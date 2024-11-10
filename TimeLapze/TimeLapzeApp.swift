import AVFoundation
import SwiftUI
import UserNotifications
import SettingsAccess

@main
struct TimeLapzeApp: App {
    @NSApplicationDelegateAdaptor(TimeLapzeAppDelegate.self) var appDelegate
    
    // Top-Level View Model
    @ObservedObject var recorderViewModel = RecorderViewModel()
    @ObservedObject var preferencesViewModel = PreferencesViewModel()
    @ObservedObject var onboardingViewModel = OnboardingViewModel()
    
    var body: some Scene {
        // onboarding view (order matters here)
        WindowGroup(id: "onboarding"){
            if !onboardingViewModel.onboarded {
                OnboardingView()
                    .environmentObject(onboardingViewModel).environmentObject(recorderViewModel)
                    .openSettingsAccess()
            }
        }.windowResizability(.contentSize)
            .windowStyle(.hiddenTitleBar)
            .windowToolbarStyle(.unifiedCompact)
        
        // main view
        MenuBarExtra {
            ContentView().environmentObject(recorderViewModel)
        } label: {
            Image(systemName: recorderViewModel.state.description).accessibilityLabel(
                "ScreenTimeLapse MenuBar")
        }.onChange(of: recorderViewModel.state, initial: false){
            Task {
                await recorderViewModel.getDisplayInfo()
            }
        }

        Settings {
            PreferencesView().environmentObject(preferencesViewModel)
            .onAppear{
              NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
    }
}

/// General purpose `NSApplicationDelegate` and `UNUserNotificationCenterDelegate`
/// Abstracts away custom features unable to be set in `info.plist` or any other config files
class TimeLapzeAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate
{
    /// Triggered when the application finished launching and receives a launch notification `Notification` on the event
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
                        logger.error("Permissions denied")
                    }
                }
            @unknown default:
                logger.error("Unknown default")
            }
        }
        
        // Setting the notification delegate
        UNUserNotificationCenter.current().delegate = self
    }
    
    /// Creates a custom dock menu with the `play`, `pause` and `settings` buttons in a Spotify-like manner
    /// Not used.
    @MainActor
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        
        menu.addItem(
            NSMenuItem(title: "Start Recording", action: nil, keyEquivalent: "testing")
        )
        
        menu.addItem(
          NSMenuItem(title: "Pause Recording", action: nil, keyEquivalent: "testing")
        )
      
        return menu
    }
    
    /// Handles when a user clicks on a notification uses the `response.notification.request.content.userInfo` to read attached data to open the `fileURL` key
    func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        
        // opens the file just saved
        if let filePath = response.notification.request.content.userInfo["fileURL"] as? String,
           let fileURL = URL(string: filePath)
        {
            workspace.open(fileURL)
        }
        
        // completion handler things: `nil` in this case
        completionHandler()
    }
}
