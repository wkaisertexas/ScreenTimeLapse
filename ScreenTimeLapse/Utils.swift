import Foundation
import ScreenCaptureKit
import AVFoundation

/// Output information consists of details about each stream designed to be shared by a recorder view model
struct OutputInfo{
    var frameRate: Float = 25.0
    var timeDivisor: Float = 25.0
    
    /// Determines the time each frame should be shown on the screen
    func getFrameTime() -> Float { 1 / self.frameRate * self.timeDivisor}
}

/// Represents the possible states of the recording system
/// Converting into a string yields the app's icon
enum RecordingState : CustomStringConvertible{
    var description: String {
        switch self{
            case .stopped:
                return "🔴"
            case .paused:
                return "▶️"
            case .recording:
                return "⏸️"
        }
    }
    
    case stopped
    case recording
    case paused
}

extension SCRunningApplication : Comparable{
    public static func < (lhs: SCRunningApplication, rhs: SCRunningApplication) -> Bool {
        lhs.bundleIdentifier < rhs.bundleIdentifier
    }
}

// can add sample buffer
func canAddSampleBuffer(buffer: CMSampleBuffer, assetWriterInput: AVAssetWriterInput) -> Bool {
    // buffer should be valid
    guard buffer.isValid else {
        print("Buffer is not valid")
        return false
    }
    
    // writer input should have room for more media data
    guard assetWriterInput.isReadyForMoreMediaData else {
        print("The input is not ready for more media data ")
        return false
    }
    
    // timing info
    guard buffer.presentationTimeStamp.timescale == assetWriterInput.mediaTimeScale else {
        print("The timescales are off")
        print("Timescale buffer \(buffer.presentationTimeStamp.timescale)")
        print("Timescale input \(assetWriterInput.mediaTimeScale)")
        return false
    }
    
    // we work with single samples
    guard buffer.totalSampleSize == 1 else {
        print("Samples \(buffer.totalSampleSize)")
        return false
    }
    
    // dimensions should match
    guard let bufferDescription = buffer.formatDescription, let hint = assetWriterInput.sourceFormatHint, bufferDescription.dimensions.width == hint.dimensions.width, bufferDescription.dimensions.height == hint.dimensions.height else {
        print("Dimensions are not matching")
        return false
    }
    
    print("Buffer Media Type \(bufferDescription.mediaType)")
    
    print("Buffer \(buffer)")
    print("Input \(assetWriterInput)")
    return true
}
