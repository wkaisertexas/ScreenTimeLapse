import AVFoundation
import SwiftUI
import UserNotifications
import SettingsAccess

@main
struct TimeLapzeApp: App {
    @NSApplicationDelegateAdaptor(TimeLapzeAppDelegate.self) var appDelegate
    
    // Top-Level View Model
    @ObservedObject var recorderViewModel = RecorderViewModel.shared
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
     
      let recorderViewModel = RecorderViewModel.shared
      let disabled = recorderViewModel.recordersDisabled()

      if recorderViewModel.state == .stopped {
        let startItem = NSMenuItem(title: String(localized: "Start Recording"), action: disabled ? nil : #selector(startRecording), keyEquivalent: "")
        startItem.target = self
        menu.addItem(startItem)
      }
     
      if recorderViewModel.state == .recording {
        let pauseItem = NSMenuItem(title: String(localized: "Pause Recording"), action: disabled ? nil : #selector(pauseRecording), keyEquivalent: "")
        pauseItem.target = self
        menu.addItem(pauseItem)
      }

      if recorderViewModel.state == .paused {
        let pauseItem = NSMenuItem(title: String(localized: "Resume Recording"), action: disabled ? nil : #selector(resumeRecording), keyEquivalent: "")
        pauseItem.target = self
        menu.addItem(pauseItem)
      }
      
      if recorderViewModel.state == .recording || recorderViewModel.state == .paused {
        let stopAndSave = NSMenuItem(title: String(localized: "Exit and Save Recording"), action: disabled ? nil : #selector(pauseRecording), keyEquivalent: "")
        stopAndSave.target = self
        menu.addItem(stopAndSave)
      }
      
      return menu
    }

    @objc func startRecording() {
        RecorderViewModel.shared.startRecording()
    }
    
    @objc func pauseRecording() {
        RecorderViewModel.shared.pauseRecording()
    }
  
    @objc func resumeRecording() {
      RecorderViewModel.shared.resumeRecording()
    }
  
    @objc func stopRecording() {
      RecorderViewModel.shared.saveRecordings()
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
