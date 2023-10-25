import Foundation
import AVFoundation
import ScreenCaptureKit
import Combine

import AppKit // TODO: remove this

import SwiftUI // for CI images

// TODO: remove for testing purposes
var frameCount = 0
var offset: CMTime = CMTime(seconds: 0.0, preferredTimescale: 60)

/// Represents an object interactable with a ``RecorderViewModel``
protocol Recordable : CustomStringConvertible {
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
        
                print("Handle video called")
        guard self.input != nil else { // both
            logger.error("No AVAssetWriter with the name `input` is present")
            return
        }
        
        do{
            guard let attachmentsArray : NSArray = CMSampleBufferGetSampleAttachmentsArray(buffer,
                                                                                          createIfNecessary: false),
            var attachments : NSDictionary = attachmentsArray.firstObject as? NSDictionary
            else {
                logger.error("Attachments Array does not work")
                return
            }
                                                                                                
            // the status needs to be not `.complete`
            print(attachments)
            guard let rawStatusValue = attachments[SCStreamFrameInfo.status] as? Int, let status = SCFrameStatus(rawValue: rawStatusValue), status == .complete else {
                return }
            
            guard let writer = self.writer, let input = self.input else {return}
            
            if writer.status == .unknown {
               writer.startWriting()
                    
                let latency = attachments.value(forKey: "SCStreamMetricCaptureLatencyTime") as! Double
                print(latency)
                
                writer.startSession(atSourceTime: .zero)
                
                offset = try buffer.sampleTimingInfos().first!.presentationTimeStamp
                return
            }
            
            guard writer.status != .failed else {
                logger.log("WE failed")
                return
            }
            
            canAddSampleBuffer(buffer: buffer, assetWriterInput: input)
            
            input.append(try buffer.offsettingTiming(by: offset))
            logger.log("Appended buffer")
        } catch {
            logger.error("Invalid framebuffer")
        }
    }
}



func printSampleBufferSize(sampleBuffer: CMSampleBuffer) {
    guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
        print("Failed to get format description")
        return
    }
    
    let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
    let width = Int(dimensions.width)
    let height = Int(dimensions.height)
    
    print("Width: \(width), Height: \(height)")
}


extension CMSampleBuffer {
    func offsettingTiming(by offset: CMTime) throws -> CMSampleBuffer {
        let newSampleTimingInfos: [CMSampleTimingInfo]
        
        do {
            newSampleTimingInfos = try sampleTimingInfos().map {
                var newSampleTiming = $0
                newSampleTiming.presentationTimeStamp = CMTimeMultiplyByFloat64($0.presentationTimeStamp - offset, multiplier: 0.2)
                print(newSampleTiming)

                return newSampleTiming
            }
        } catch {
            newSampleTimingInfos = []
        }
        let newSampleBuffer = try CMSampleBuffer(copying: self, withNewTiming: newSampleTimingInfos)
        return newSampleBuffer
    }
}
