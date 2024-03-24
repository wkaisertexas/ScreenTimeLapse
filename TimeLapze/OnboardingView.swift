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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack{
            Group{
                switch viewModel.onWindow {
                case .introPage:
                    card(title: "Welcome to TimeLapze", subtitle: "TimeLapze is a tool for creating screen and camera time lapses", image: "OnboardingIntro", index: 0)
                case .menuBarPage:
                    card(title: "TimeLapze lives in the menu bar", subtitle: "Start, pause, resume, and save all of your recordings through the menu bar interface", image: "OnboardingMenuBar", index: 1)
                case .timeMultiplePage:
                    card(title: "Define Your Time Multiple", subtitle: "Your time multiple is how much faster your output video is than real life", image: "OnboardingTimeMultiple", index: 2)
                case .filteringPage:
                    card(title: "Filter out unwanted apps", subtitle: "Edit the enabled and disabled list to avoid recording unwanted apps", image: "OnboardingFilterApps", index: 3)
                case .cameraPage:
                    card(title: "Record many screens and cameras", subtitle: "Click any camera or screen to record it", image: "OnboardingMultipleDevices", index: 4)
                case .getStarted:
                    card(title: "Get started creating TimeLapzes", subtitle: "Recording are always color-accurate and crazy performant", image: "OnboardingGetStarted", index: 5)
                }
            }
        }.frame(width: 466, height: 483, alignment: .leading)
    }
    
    // MARK: Intents
    
    /// Shows the `settings` in accordance with the tutorial
    func showSettings(){
        if !viewModel.settingsShown {
            try? openSettings()
        }
        
        viewModel.settingsShown = true
    }
   
    // MARK: Components

    /// Standard onboarding card template every slide will use
    func card(title: LocalizedStringKey, subtitle: LocalizedStringKey, image: String, index: Int) -> some View {
        ZStack{
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
                .overlay(DrawingConstants.overlayGradient)
                .transition(.push(from: .leading))
                .accessibilityIdentifier("feature_background")
            VStack (alignment: .leading){
                VStack(alignment: .leading, spacing: 8){
                    Text(title)
                        .fontWeight(.bold)
                        .fontWidth(.condensed)
                        .font(.title)
                        .accessibilityIdentifier("feature_title")

                    Text(subtitle)
                            .fontWeight(.medium)
                            .fontWidth(.expanded)
                            .font(.subheadline)
                            .frame(maxWidth: (466 - 80) / 3 * 2, alignment: .leading)
                            .accessibilityIdentifier("feature_subtitle")
                }.transition(.move(edge: .leading))
                
                Spacer()
                
                let baseCircle = Circle().stroke(lineWidth: 2).fill(.gray).frame(width: 9, height: 9).opacity(0.2)
                HStack{
                    ForEach(0..<6, id: \.self) { id in
                        if id == index {
                            baseCircle.background(Circle().fill(.blue))
                        } else {
                            baseCircle
                        }
                    }
                }
                bottomNav(viewModel.onWindow)
            }.padding(40)
                .transition(.slide)
        }
    }
    
    func bottomNav(_ window: OnboardingWindows) -> some View {
        HStack{
            viewModel.hasPrev ? Button("Previous"){
                viewModel.previousWindow()
            }.buttonStyle(.bordered).focusable(false) : nil
            
            Spacer()
            
            Button("Skip"){
                dismiss()
            }.buttonStyle(.borderless).focusable(false)
            
            viewModel.hasNext ? Button("Next", systemImage: "chevron.right"){
                withAnimation {
                    viewModel.nextWindow()
                }
            }.buttonStyle(.borderedProminent) : nil
            
            !viewModel.hasNext ? Button(action: {
                viewModel.skipOnboarding()
                dismiss()
            },
                                       label: {
                Text("Get Started")
                Image(systemName: "record.circle.fill")
            }).buttonStyle(.borderedProminent) : nil
        }
    }
    
    
    // MARK: Drawing constants
    struct DrawingConstants{
        static let overlayGradient = LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.8), Color.clear]),
                                             startPoint: .top, endPoint: .bottom)
    }
}

#Preview {
    OnboardingView()
}
