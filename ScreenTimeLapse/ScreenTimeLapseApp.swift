import SwiftUI
import AVFoundation

var mainBody: RecordVideo?

@main
struct ScreenTimeLapseApp: App {
    @ObservedObject var recorderViewModel = RecorderViewModel()

    var body: some Scene {
        Window("My window", id: "Main Window"){
            Button("Start recording"){
                            let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: AVMediaType.video, position: .unspecified)
                
                            // get the front camera
                            print(discovery.devices)
                            let camera = discovery.devices.first { device in
                                device.manufacturer == "Apple Inc."
                            }!
                
                mainBody = RecordVideo(device: camera)
                sleep(15)
            }
        }
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
