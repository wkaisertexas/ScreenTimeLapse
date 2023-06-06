import Foundation
import ScreenCaptureKit
import AVFoundation
import SwiftUI

/// Records the output of a screen in a stream-like format
class Screen: NSObject, SCStreamOutput, Recordable {
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
    
    // MARK: -User Interaction
    func startRecording() {
        guard self.enabled else { return }
        guard self.state != .recording else { return }
        
        self.state = .recording
        setup(path: getFilename(), excluding: []) // TODO: implement logic which actually gets the excluding
    }
    
    func pauseRecording() {
        self.state = .paused
    }
    
    func resumeRecording() {
        self.state = .recording
    }
    
    func saveRecording() {
        guard self.enabled else { return }
        
        self.state = .stopped
        
        logger.log("Screen -- saved recording")
        
        // given this is a UI task, the main thread is running this application
        // screen recording is happening on another thread, a screen recorder might
        // be in the middle of appending data or handling data when this is happening
       
        // the stream of data needs to be stopped as per my notes on this
        // a pseudo-blocking data structure needs to exist to wait until the status is non-zero
        
        if let stream = stream {
            stream.stopCapture()
        }
        
        while(!(input?.isReadyForMoreMediaData ?? false)){
            logger.log("Not able to mark the stream as finished")
            sleep(1) // sleeping for a second
        }
        
        input?.markAsFinished()
        writer!.finishWriting { [self] in
            if self.writer!.status == .completed {
                // Asset writing completed successfully
            } else if writer!.status == .failed {
                // Asset writing failed with an error
                if let error = writer!.error {
                    logger.error("Asset writing failed with error: \(error.localizedDescription)")
                }
            }
        }
        // TODO: save the file
    }
    
    func setup(path: String, excluding: [SCRunningApplication]) {
        Task(priority: .userInitiated){
            do{
                (self.writer, self.input) = try setupWriter(screen: screen, path: path)
                
                logger.log("Setup Asset Writer \(self.writer)")
                logger.log("Setup Asset Input \(self.input)")
                
                try setupStream(screen: screen, showCursor: showCursor, excluding: excluding)
                
                logger.debug("Setup stream")
            } catch{
                logger.error("Failed to setup stream")
            }
        }
    }
       
    func setupWriter(screen: SCDisplay, path: String) throws -> (AVAssetWriter, AVAssetWriterInput) {
        // Creates the video input
        let videoOutputSettings: [String : Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: screen.width,
            AVVideoHeightKey: screen.height,
        ]
        
        let audioOutputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44_100,
            AVEncoderBitRateKey: 128_000,
        ]
        
        let url = URL(string: path, relativeTo: .temporaryDirectory)!

        logger.log("URL: \(url)")
        logger.log("Path: \(path)")
        let writer = try AVAssetWriter(url: url, fileType: .mov)
                        
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoOutputSettings)
        
        logger.log("Can I add the AssetWriterInput? \(writer.canAdd(input))")
        
        writer.add(input) // TODO: Check if connecting these makes this work
        
        debugPrintStatus(writer.status)
        
        return (writer, input)
    }
    
    func setupStream(screen: SCDisplay, showCursor: Bool, excluding: [SCRunningApplication]) throws {
        let contentFilter = SCContentFilter(
            display: screen,
            excludingApplications: excluding,
            exceptingWindows: []
        )
        
        let config = SCStreamConfiguration()
        config.width = screen.width
        config.height = screen.height
        config.showsCursor = showCursor
        
        stream = SCStream(
            filter: contentFilter,
            configuration: config,
            delegate: StreamDelegate()
        )
        
        try stream!.addStreamOutput(
            self,
            type: .screen,
            sampleHandlerQueue: .global(qos: .userInitiated)
        )
        
        stream!.startCapture(completionHandler: handleStreamStartFailure)
    }
    
    func stream(_ stream: SCStream, didOutputSampleBuffer: CMSampleBuffer, of: SCStreamOutputType) {
        guard self.state == .recording else { return }
        
        logger.debug("Output of the sample buffer")
        guard didOutputSampleBuffer.isValid else {
            logger.error("The sample buffer IS NOT valid")
            return
        }
        
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
        let randomValue = Int(arc4random_uniform(100_000)) + 1
        return "\(screen.displayID)-\(randomValue).mov"
    }
}

class StreamDelegate : NSObject, SCStreamDelegate{
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("The stream stopped")
    }
}
