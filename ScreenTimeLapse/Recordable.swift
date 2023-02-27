import Foundation
import AVFoundation
import ScreenCaptureKit

/// Represents an object interactable with a `RecorderViewModel`
protocol Recordable : CustomStringConvertible{
    var metaData: OutputInfo {get set}
    var state: RecordingState {get set}
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
