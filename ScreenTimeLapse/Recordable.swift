import AVFoundation
import ScreenCaptureKit

// TODO: remove for testing purposes
var frameCount = 0

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
}

// Allows timings offsets
extension CMSampleBuffer {
    func offsettingTiming(by offset: CMTime, multiplier: Float64) throws -> CMSampleBuffer {
        let newSampleTimingInfos: [CMSampleTimingInfo]
        
        do {
            newSampleTimingInfos = try sampleTimingInfos().map {
                var newSampleTiming = $0
                newSampleTiming.presentationTimeStamp = offset + CMTimeMultiplyByFloat64($0.presentationTimeStamp - offset, multiplier: multiplier)
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
