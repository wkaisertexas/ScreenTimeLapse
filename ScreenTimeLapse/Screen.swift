import Foundation
import ScreenCaptureKit
import AVFoundation


/// Records the output of a screen in a stream-like format
class Screen: NSObject, SCStreamOutput, Recordable{
    var state: RecordingState = .stopped
    var lastSavedFrame: CMTime?
    var metaData: OutputInfo = OutputInfo()
    var enabled: Bool = false
    var writer: AVAssetWriter?
    var input: AVAssetWriterInput?
    
    // ScreenCaptureKit-Specific Functionality
    var screen: SCDisplay
    var stream: SCStream?
    var showCursor: Bool
    
    override var description: String {
        "[\(screen.width) x \(screen.height)] - Display \(screen.displayID)"
    }
    
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
        "\(screen.displayID)-\(CMTime().seconds).mp4"
    }
}

class StreamDelegate : NSObject, SCStreamDelegate{
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("The stream stopped")
    }
}
