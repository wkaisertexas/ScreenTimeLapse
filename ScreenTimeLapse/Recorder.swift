import Foundation
import AVFoundation
import ScreenCaptureKit

/// Output information consists of details about each stream designed to be shared by a recorder view model
struct OutputInfo{
    var frameRate: Float = 25.0
    var timeDivisor: Float = 25.0
    
    /// Determines the time each frame should be shown on the screen
    func getFrameTime() -> Float { 1 / self.frameRate * self.timeDivisor}
}

/// Represents an object interactable with a `RecorderViewModel`
protocol Recordable{
    var metaData: OutputInfo {get set}
    var state: State {get set}
    var enabled: Bool {get set}
    
    var writer: AVAssetWriter? {get set}
    var input: AVAssetWriterInput? {get set}
    var lastSavedFrame: CMTime? {get set}
    
    // MARK: -Intents
    mutating func startRecording()
    mutating func stopRecording()
    mutating func resumeRecording()
    mutating func pauseRecording()
    mutating func saveRecording()
    
    func getFilename() -> String
}

extension Recordable{
    mutating func startRecording() {
        self.state = .recording
    }
    
    mutating func stopRecording() {
        self.state = .stopped
        saveRecording()
    }
    
    mutating func resumeRecording(){
        self.state = .recording
    }
    
    mutating func pauseRecording() {
        self.state = .paused
    }
    
    mutating func saveRecording() {
        print("Saving recorder")
    }
    
    /// Uses the frame rate and duration to determine if the frame should be saved
    mutating func shouldSaveVideo(buffer: CMSampleBuffer) -> Bool{
        let maxTime = buffer.presentationTimeStamp + buffer.duration
        
        if let last = self.lastSavedFrame {
            if maxTime.seconds < last.seconds + Double(metaData.getFrameTime()){
                self.lastSavedFrame = maxTime
                return true
            }
            
            return false
        } else {
            self.lastSavedFrame = maxTime
            return true
        }
    }
    
    /// Provides a default way to deal with streams which do not work
    func handleStreamStartFailure(err: Error?){
        print("\(String(describing: err))")
    }
    
    func handleVideo(buffer: CMSampleBuffer){
        do{
            let buffers = try buffer.singleSampleBuffers()
            
            // TODO: Make this work properly by writing tests in case the orders are wrong
            
            for singleBuffer in buffers{
                self.input?.append(singleBuffer)
            }
        } catch {
            print("Invalid framebuffer")
        }
    }
}

class Camera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, Recordable{
    var state: State = .stopped
    var metaData: OutputInfo = OutputInfo()
    var enabled: Bool = false
    var writer: AVAssetWriter?
    var input: AVAssetWriterInput?
    var lastSavedFrame: CMTime?
    
    // Audio Video Capture-Specific Functionality
    var inputDevice: AVCaptureDevice
    
    init(camera: AVCaptureDevice){
        self.inputDevice = camera
    }
    
    func setup(path: String) throws {
        
    }
    
    // MARK: -Streaming
    
    /// Equivalent to `stream` for `Screen`. Takes sample buffers and processes them
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        handleVideo(buffer: sampleBuffer)
    }
    
    func getFilename() -> String {
        "nothing.mp4"
    }
}

class Screen: NSObject, SCStreamOutput, Recordable{
    var state: State = .stopped
    var lastSavedFrame: CMTime?
    var metaData: OutputInfo = OutputInfo()
    var enabled: Bool = false
    var writer: AVAssetWriter?
    var input: AVAssetWriterInput?
    
    // ScreenCaptureKit-Specific Functionality
    var screen: SCDisplay
    var stream: SCStream?
    var showCursor: Bool
    
    init(screen: SCDisplay, showCursor: Bool) {
        self.screen = screen
        self.showCursor = showCursor
    }
    
    func setup(path: String, excluding: [SCRunningApplication]) throws {
        (self.writer, self.input) = try setupWriter(screen: screen, path:path)
        try setupStream(screen: screen, showCursor: showCursor, excluding: excluding)
    }
       
    func setupWriter(screen: SCDisplay, path: String) throws -> (AVAssetWriter, AVAssetWriterInput) {
        // Creates the video input
        let outputSettings: [String : Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: screen.width,
            AVVideoHeightKey: screen.height
        ]
        
        let url = URL(fileURLWithPath: path, isDirectory: false)
        let writer = try AVAssetWriter(url: url, fileType: .mov)
        
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        
        return (writer, input)
    }
    
    func setupStream(screen: SCDisplay, showCursor: Bool, excluding: [SCRunningApplication]) throws {
        let contentFilter = SCContentFilter(display: screen, excludingApplications: excluding, exceptingWindows: [])
        
        let config = SCStreamConfiguration()
        config.width = screen.width
        config.height = screen.height
        config.showsCursor = showCursor
        
        let stream = SCStream(filter: contentFilter, configuration: config, delegate: StreamDelegate())
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .global(qos: .background))
        
        stream.startCapture(completionHandler: handleStreamStartFailure)
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer: CMSampleBuffer, of: SCStreamOutputType) {
        switch of{
            case .screen:
                handleVideo(buffer: didOutputSampleBuffer)
            case .audio:
                print("Audio should not be captured")
            default:
                print("Unknown future case")
        }
    }
    
    func getFilename() -> String {
        "nothing.mp4"
    }
}

class StreamDelegate : NSObject, SCStreamDelegate{
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("The stream stopped")
    }
}
