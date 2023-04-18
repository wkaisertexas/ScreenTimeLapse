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
        if self.state == .recording{
            return;
        }
        // setup recording



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
        if let error = err{
            print("Stream start failure")
            print("\(String(describing: error))")
        } else{
            print("Stream started sucessfully")
        }
    }
    
    /// Receives a list of `CMSampleBuffers` and uses `shouldSaveVideo` to determine whether or not to save a video
    func handleVideo(buffer: CMSampleBuffer){
        print("Handling video")
        if let inputter = self.input{
            print("the input is there")
        }
        do{
            try buffer
                .singleSampleBuffers()
                .filter{ _ in // todo: fix this
                    true
                }
                .forEach{ buffer in
                    while(!(self.input?.isReadyForMoreMediaData ?? true)){
                        sleep(1)
                        print("Sleeping")
                        print(self.input?.isReadyForMoreMediaData ?? nil)
                    }
                    self.input?.append(buffer)
                    
//                    AVAssetWriterInputPixelBufferAdaptor.append(input).(buffer, withPresentationTime: T##CMTime)
                }
        } catch {
            print("Invalid framebuffer")
        }
    }
}
