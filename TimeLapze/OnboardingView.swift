import SwiftUI
import AppKit

/// Represents each window of the ``OnboardingView``
enum OnboardingWindows {
    case introPage
    case menuBarPage
    case timeMultiplePage
    case filteringPage
    case cameraPage
    case getStarted
   
    /// Gets the next enum present
    func next() -> OnboardingWindows {
        switch self {
        case .introPage:
            return .menuBarPage
        case .menuBarPage:
            return .timeMultiplePage
        case .timeMultiplePage:
            return .filteringPage
        case .filteringPage:
            return .cameraPage
        case .cameraPage:
            return .getStarted
        default:
            logger.error("There is no next to the last page")
            return .introPage
        }
    }
    
    /// Gets the previous window present
    func prev() -> OnboardingWindows {
        switch self {
        case .getStarted:
            return .cameraPage
        case .cameraPage:
            return .filteringPage
        case .filteringPage:
            return .timeMultiplePage
        case .timeMultiplePage:
            return .menuBarPage
        case .menuBarPage:
            return .introPage
        default:
            logger.error("There is no previous to the first page")
            return .introPage
        }
    }
    
    /// Checks if a window has a previous
    var hasPrev: Bool {
        switch self {
        case .introPage:
            return false
        default:
            return true
        }
    }
    
    /// Checks if a window has a next
    var hasNext: Bool {
        switch self {
        case .getStarted:
            return false
        default:
            return true
        }
    }
}

/// Onboarding view which uses a menu-bar less window to show onboarding information
struct OnboardingView: View {
    @EnvironmentObject private var recorderViewModel: RecorderViewModel
    @EnvironmentObject private var viewModel: OnboardingViewModel
   
    // Opens the settings (requires injection)
    @Environment(\.openSettings) private var openSettings
    
    var body: some View {
        VStack{
            switch viewModel.onWindow {
            case .introPage:
                introduction()
            case .menuBarPage:
                menubar()
            case .timeMultiplePage:
                timeMultiple()
            case .filteringPage:
                filtering()
            case .cameraPage:
                recordCamera()
            case .getStarted:
                startRecording()
            }
            
            Spacer()
            
            bottomNav(viewModel.onWindow)
                .padding(5)
        }.frame(width: 350, height: 500, alignment: .topLeading)
            .ignoresSafeArea(.all)
    }
    
    // MARK: Intents
    /// Shows the `settings` in accordance with the tutorial
    func showSettings(){
        if !viewModel.settingsShown {
            try? openSettings()
        }
        
        viewModel.settingsShown = true
    }
    
    
    // MARK: Pages
    
    /// Represents the first screen the user will see
    func introduction() -> some View {
        VStack{
            Image("IntroScreen")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .edgesIgnoringSafeArea(.all)
            VStack{
                Text("Welcome to TimeLapze")
                    .fontWeight(.medium)
                    .fontWidth(.compressed)
                    .font(.title)
                Text("TimeLapze is a tool for creating screen and camera time lapses")
                    .fontWidth(.expanded)
                    .font(.subheadline)
            }
        }
    }
   
    /// Explains how ``TimeLapze`` is a menu-bar application
    func menubar() -> some View {
        VStack {
            Image("menubar")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Text("TimeLapze lives in the menu bar")
                    .fontWeight(.medium)
                    .fontWidth(.compressed)
                    .font(.title)
                Text("Start, pause, resume, and save all of your recordings through the menu bar interface")
                    .fontWidth(.expanded)
                    .font(.subheadline)
            }
        }
    }
  
    /// Explains how a time multiple works
    func timeMultiple() -> some View {
        VStack {
            Image("timeMultiple")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Text("Define Your Time Multiple")
                    .fontWeight(.medium)
                    .fontWidth(.compressed)
                    .font(.title)
                Text("Your time multiple is how much faster your output video than real life")
                    .fontWidth(.expanded)
                    .font(.subheadline)
            }
        }
    }
    
    /// Explains how filtering works
    func filtering() -> some View {
        VStack {
            Image("filtering")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Text("Filter out unwanted apps")
                    .fontWeight(.medium)
                    .fontWidth(.compressed)
                    .font(.title)
                Text("Edit the enabled and disabled list to not record unwanted apps")
                    .fontWidth(.expanded)
                    .font(.subheadline)
            }
        }
    }
    
    
    /// Record your camera too
    func recordCamera() -> some View {
         VStack {
            Image("recordCamera")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Text("Record many screens and cameras")
                    .fontWeight(.medium)
                    .fontWidth(.compressed)
                    .font(.title)
                Text("Click any camera or screen to record it")
                    .fontWidth(.expanded)
                    .font(.subheadline)
            }
        }
    }
    
    /// Final CTA screen
    func startRecording() -> some View {
         VStack {
            Image("startRecording")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Text("Get started creating TimeLapzes")
                    .fontWeight(.medium)
                    .fontWidth(.compressed)
                    .font(.title)
                Text("Recording are always color-accurate and crazy performant")
                    .fontWidth(.expanded)
                    .font(.subheadline)
            }
        }
    }
    
    // MARK: Components
    
    func bottomNav(_ window: OnboardingWindows) -> some View {
        HStack{
            viewModel.hasPrev ? Button("Previous"){
                viewModel.previousWindow()
            }.buttonStyle(.bordered).focusable(false) : nil
            
            Spacer()
            
            Button("Skip"){
                viewModel.skipOnboarding()
            }.buttonStyle(.borderless).focusable(false)
            
            viewModel.hasNext ? Button("Next", systemImage: "chevron.right"){
                viewModel.nextWindow()
            }.buttonStyle(.borderedProminent) : nil
            
            !viewModel.hasNext ? Button(action: {
                viewModel.skipOnboarding()
            },
                                       label: {
                Text("Get Started")
                Image(systemName: "record.circle.fill")
            }).buttonStyle(.borderedProminent) : nil
        }
    }
    
}

#Preview {
    OnboardingView()
}
