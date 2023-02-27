import SwiftUI

@main
struct ScreenTimeLapseApp: App {
    @ObservedObject var recorderViewModel = RecorderViewModel()
    //    let persistenceController = PersistenceController.shared

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
