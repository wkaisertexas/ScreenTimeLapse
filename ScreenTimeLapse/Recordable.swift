import Foundation
import AVFoundation
import ScreenCaptureKit

import AppKit // TODO: remove this

import SwiftUI // for CI images

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
        guard self.enabled else { return }
        guard self.state != .recording else { return }
        
        logger.log("This should not run")
        
        self.state = .recording
    }
    
    mutating func stopRecording() {
        guard self.enabled else { return }
        
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
        logger.log("Saving recorder")
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
            logger.log("Stream start failure \(String(describing: error))")
        } else{
            logger.log("Stream started sucessfully")
        }
    }
    
    /// Receives a list of `CMSampleBuffers` and uses `shouldSaveVideo` to determine whether or not to save a video
    func handleVideo(buffer: CMSampleBuffer){
        guard self.input != nil else {
            logger.error("No AVAssetWriter with the name `input` is present")
            return
        }
        
        do{            
            try buffer
                .singleSampleBuffers()
                .filter{ _ in // todo: fix this
                    true
                }
                .forEach{ buffer in
                    if self.writer?.status == .unknown {
                        self.writer?.startWriting()
                        self.writer?.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(buffer))
                        logger.log("Started recording session because the writer's status was not known")
                    } else {
                        debugPrintStatus(self.writer!.status)
                    }
                    
                    while(!(self.input?.isReadyForMoreMediaData ?? true)){
                        sleep(1)
                        logger.log("Sleeping")
                    }
                    
                    self.input?.append(buffer)
                    logger.log("Appended framebuffer")
                }
        } catch {
            logger.error("Invalid framebuffer")
        }
    }
}
