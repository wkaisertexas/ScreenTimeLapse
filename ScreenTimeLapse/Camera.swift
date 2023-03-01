import Foundation
import AVFoundation


/// Records the output of a camera in a stream-like format
class Camera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, Recordable{
    var state: RecordingState = .stopped
    var metaData: OutputInfo = OutputInfo()
    var enabled: Bool = false
    var writer: AVAssetWriter?
    var input: AVAssetWriterInput?
    var lastSavedFrame: CMTime?
    
    // Audio Video Capture-Specific Functionality
    var inputDevice: AVCaptureDevice
    
    override var description: String {
        if inputDevice.manufacturer.isEmpty{
            return "\(self.inputDevice.localizedName)"
        } else{
            return "\(self.inputDevice.localizedName) - \(inputDevice.manufacturer)"
        }
    }
    
    init(camera: AVCaptureDevice){
        self.inputDevice = camera
    }
    
    func setup(path: String) {
        
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
