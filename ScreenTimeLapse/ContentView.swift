//
//  ContentView.swift
//  ScreenTimeLapse
//
//  Created by William Kaiser on 1/1/23.
//

import SwiftUI
import CoreData
import AVFoundation
import ScreenCaptureKit
import Foundation

enum state{
    case stopped
    case recording
    case paused
}

// Properties
let HELP = "https://apple.com"
let ABOUT = "https://apple.com"

// Notes:
// 1. Apparently, you are supposed to use a network manager or something akin to that to prevent data from being loaded prematurely, but I am not going to do that and just make a quick init function
//    - Apparently, this quick init function turned out to be much longer than excpected
// 2. Someone should have told me that SwiftUI is React for non-react people
// 3. I need to make a task and not have issues with mutating state -> Apparently, using a _ keyword could potentially hellp out with that

// TODO: Create a deafult delegate which tells the user when the stream has failed
// TODO: Make this conforms to the MVVM protocol
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.openURL) var openURL
    
    @State private var recordingState: state = .stopped
    @StateObject private var screenModel = ScreenDisplayViewModel()
    
    @State private var loadButton = "Load Apps and Displays"
    
    @State private var frame_rate = 25.0 // output is at 25 frames per second
    @State private var speed_up = 60.0 // output is 60x faster than real life
    @State private var showCursor = false
    
    let speed_formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    @State private var fr_alert = false
    @State private var su_alert = false
    
    var body: some View { // TODO: Figure out what in the fuck this should b
        switch recordingState{
        case .stopped:
            Button("Start Recording"){
                startRecording()
                recordingState = .recording
            }.keyboardShortcut("R")
        case .recording:
            Button("Pause Recording"){
                recordingState = .paused
            }.keyboardShortcut("P")
            Button("Exit Recording"){
                recordingState = .stopped
            }.keyboardShortcut("S")
        case .paused:
            Button("Resume Recording"){
                recordingState = .recording
            }.keyboardShortcut("R")
            Button("Exit Recording"){
                recordingState = .stopped
            }.keyboardShortcut("S")
        }
        Divider()
        Menu("Input Devices"){
            if screenModel.apps.count > 0{
                ForEach(screenModel.apps, id: \.self){app in
                    Button(action: {
                        screenModel.en_apps[app]?.toggle()
                    }){
                        HStack{
                            if screenModel.en_apps[app]!{
                                Image(systemName: "checkmark")
                            }
                            
                            Text(app.applicationName)
                        }
                    }
                }
            }
            
            if screenModel.displays.count > 0{
                Divider()
                
                ForEach(screenModel.displays, id: \.self){display in
                    HStack{
                        if screenModel.en_displays[display]! {
                            Image(systemName: "checkmark")
                        }
                        Button("(\(display.width) x \(display.height)) Display # \(display.displayID)"){
                            screenModel.en_displays[display]?.toggle()
                        }
                    }
                }
            }
            
            Divider()
            
            ForEach(getCameras(), id: \.self){camera in
                HStack{
                    if screenModel.cameras[camera]!{
                        Image(systemName: "checkmark")
                    }
                    
                    Button(camera.localizedName){
                        screenModel.cameras[camera]?.toggle()
                    }
                }
            }
            
        }.task{
            await screenModel.getDisplayInfo()
        }
        
        Button(String(format: "( %.1f ) Adjust frame rate", frame_rate)){
            fr_alert = true
        }.alert("Change frame rate", isPresented: $fr_alert, actions: {
            TextField("Frame rate", value: $frame_rate, format: .number)
        }, message: {
            TextField("Frame rate", value: $frame_rate, format: .number)
        })
        Button(String(format: "( %.1fx ) Adjust speed multiple", speed_up)){
            su_alert.toggle()
        }.sheet(isPresented: $su_alert){
            TextField("This is where you input the number", value: $frame_rate, format: .number)
        }
        
        HStack{
            if showCursor{
                Image(systemName: "checkmark")
            }
            
            Button(showCursor ? "Hide Cursor": "Show Cursor"){
                showCursor.toggle()
            }
        }
        
        Divider()
        Button("Help"){
            openURL(URL(string: HELP)!)
        }
        Button("About"){
            openURL(URL(string: ABOUT)!)
        }
        Button("Quit"){
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
    }
    
    // Recording-modifying Functions
    private func startRecording(){
        // Camera recording
        
        // Gets the attached cameras
        let cameras = screenModel.cameras.filter{camera in
            camera.value
        }.map{$0.key}
        
        // Gets / Makes the associated screen recording devices
        for camera in cameras{
            // Creates the file output
            let file_out = AVCaptureMovieFileOutput()
            
            // Creates the capture session
            let session = AVCaptureSession()
            
            let recorder = Recorder(fileOut: file_out, captureSession: session)
            
            screenModel.camera_recording[camera] = recorder
            
            // TODO: make the screen start recording
        }
        
        // Screen recording
        
        // Gets the selected screens
        let screens = screenModel.en_displays.filter{screen in
            screen.value
        }.map{$0.key}
        
        // Gets / Makes the associated screen recording devices
        for screen in screens{
            do{
                // TODO: Finish replacing this with the new code
                let url = URL(filePath:"\(screen.displayID).mov")
                
                let assetWriter = try AVAssetWriter(outputURL: url, fileType: .mov)
                
                let settings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: screen.width,
                    AVVideoHeightKey: screen.height
                ]
                
                let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
                
                
                assetWriter.add(videoInput) // Adds the video input setup with the correct parameters
                
                
                let bufferAdapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput)
                
                // Sets up the screen capture kit
                
                // Creates the content filter
                
                let contentFilter = SCContentFilter(display: screen, excludingApplications: screenModel.getExcludedApps(), exceptingWindows: [])
                
                // Creates the screen stream
                let streamConfig = SCStreamConfiguration() // This may able to just be null, but IDK night now
                
                streamConfig.width = screen.width
                streamConfig.height = screen.height
                streamConfig.showsCursor = showCursor
                
                let stream = SCStream(filter: contentFilter, configuration: streamConfig, delegate: nil)
                let output = SlowRecorder()
                // TODO: Implement a stream output by defining a functions which knows what to do with the stream output
            
            } catch{
                print("Failed to initalize \(screen.displayID)")
            }
        }
        
    }
    
    private func pauseRecording(){
        // Iterates through the cameras and pauses them
        
        // Iterates through the displays and pauses them
        
    }
    
    private func resumeRecording(){
        
    }
    
    private func stopRecording(){
        
    }
    
    // Properties modifying functions
    private func setFrameRate(){
        
    }
    
    private func setSpeedMultiple(){
        
    }

    /**
     Returns all the cameras connected to the computer
     */
    private func getCameras() -> [AVCaptureDevice]{
        let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: AVMediaType.video, position: .unspecified)
        return discovery.devices
    }

}


/// Links a stream output with a asset writer
class SlowRecorder : NSObject, SCStreamOutput{
    
    private var writer: AVAssetWriter
    private var input: AVAssetWriterInput
    
    // TODO: Add a bunch of variables to transfer the state (not a good way to encapsulate complexity, especially if the thing changes. All in all, my design patterns need to get far better
    
    init(path: String, screenModel: ScreenDisplayViewModel, screen: SCDisplay, showCursor: Bool){
        do{
            // Creates the asset writer
            let url = URL(fileURLWithPath: path, isDirectory: false)
            writer = try AVAssetWriter(url: url, fileType: .mov)
            
            // Creates the video input
            let outputSettings: [String : Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: screen.width,
                AVVideoHeightKey: screen.height
            ]
            input = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
            
            // Creates the content filter
            let contentFilter = SCContentFilter(display: screen, excludingApplications: screenModel.getExcludedApps(), exceptingWindows: [])
            
            // Creates the stream config
            let config = SCStreamConfiguration()
            config.width = screen.width
            config.height = screen.height
            config.showsCursor = showCursor
            // TODO: think about what a minimum frame interval should be
            
            // Creates the stream
            let stream = SCStream(filter: contentFilter, configuration: config, delegate: StreamDelegate())
            try stream.addStreamOutput(self, type: SCStreamOutputType.screen, sampleHandlerQueue: nil)
            
            stream.startCapture{ err in
                print("Stream started")
                
                if let error = err{
                    print(error)
                }
            }
    
        }catch{
            print("Unable to initialize asset writer")
        }
    }

    // TODO: Make this be what the recorder struct was intended to be
    func stream(_ stream: SCStream, didOutputSampleBuffer: CMSampleBuffer, of: SCStreamOutputType) {
        // Do nothing
        switch of{
            case .screen:
                handleVideo(buffer: didOutputSampleBuffer)
            case .audio:
                print("Audio should not be captured")
            default:
                print("Unknown future case")
        }
    }
    
    
    func handleVideo(buffer: CMSampleBuffer){
        if !buffer.isValid{
            print("Buffer is not valid")
            return
        } // I think this should call when the data is not ready
        
        // Check to see if based on the time and the speed multiple, this needs to be updated
        if true{ // FIXME: Replace with the math behind time and speed buffers
            input.append(buffer)
        }
    }
    
    func pauseRecording(){
        // Sets an internal state enum or somethign
        
        
        // Pauses the video
    }
}
