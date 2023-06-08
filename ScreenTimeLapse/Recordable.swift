import Foundation
import AVFoundation
import ScreenCaptureKit

import AppKit // TODO: remove this

import SwiftUI // for CI images

// TODO: remove for testing purposes
let frameCount = 0

/// Represents an object interactable with a ``RecorderViewModel``
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
    /// Starts recording if ``enabled``
    mutating func startRecording() {
        guard self.enabled else { return }
        guard self.state != .recording else { return }
        
        logger.log("This should not run")
        
        self.state = .recording
    }
    
    /// Stops recording if ``enabled``
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
            // Fuck it we ball, directly append the framebuffers
            if self.writer?.status == .unknown {
                let bufferTime = CMSampleBufferGetPresentationTimeStamp(buffer)
                self.writer?.startWriting()
//                self.writer?.startSession(atSourceTime: bufferTime)
                
                self.writer?.startSession(atSourceTime: CMTime(value: 1, timescale: 24))
                
                logger.debug("Buffer Time: \(buffer.presentationTimeStamp.epoch.description)")
                return
            }
            
            if self.writer?.status == .failed {
                logger.log("WE failed")
            }
            
            guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(buffer,
                  createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
                  let attachments = attachmentsArray.first else {
                logger.error("Attachments Array does not work")
                return
            }
            
            // the status needs to be not `.complete`
            guard let rawStatusValue = attachments[SCStreamFrameInfo.status] as? Int, let status = SCFrameStatus(rawValue: rawStatusValue), status == .complete else {
                logger.error("INCOMPLETE FRAMEBUFFER")
                return
            }
            
            logger.log("Tried to append buffer")
            
            
            let maker = CMTime(value: 1, timescale: 23)
            let multiplication = CMTimeMultiply(maker, multiplier: Int32(frameCount))
            
            try buffer.setOutputPresentationTimeStamp(multiplication)
            self.input?.append(buffer)
            logger.log("Appended buffer")
           
//            try buffer
//                .singleSampleBuffers()
//                .filter{ _ in // todo: fix this
//                    true
//                }
//                .forEach{ buffer in
//                    if self.writer?.status == .unknown {
//                        self.writer?.startWriting()
//                        self.writer?.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(buffer))
//                        logger.log("Started recording session because the writer's status was not known")
//                    } else {
//                        debugPrintStatus(self.writer!.status)
//                    }
//
//                    while(!(self.input?.isReadyForMoreMediaData ?? true)){
//                        sleep(1)
//                        logger.log("Sleeping")
//                    }
//
//                    self.input?.append(buffer)
//                    logger.log("Appended framebuffer")
        } catch {
            logger.error("Invalid framebuffer")
        }
    }
}
