import ScreenCaptureKit
import AVFoundation
import SwiftUI

let workspace = NSWorkspace.shared

/// Records the output of a `SCDisplay` in a stream-like format using `SCStreamOutput`
///
/// Saves `CMSampleBuffers` into ``input`` and outputs then to ``writer``
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
    var apps: [SCRunningApplication : Bool] = [:]
    var showCursor: Bool
    
    // Recording timings
    var offset: CMTime = CMTime(seconds: 0.0, preferredTimescale: 60)
    var timeMultiple: Double = 1 // offset set based on settings
        
    override var description: String {
        "[\(screen.width) x \(screen.height)] - Display \(screen.displayID)"
    }
    
    init(screen: SCDisplay, showCursor: Bool, apps: [SCRunningApplication : Bool]) {
        self.screen = screen
        self.showCursor = showCursor
        self.apps = apps
    }
    
    // MARK: -User Interaction
    func startRecording(excluding: [SCRunningApplication]) {
        guard self.enabled else { return }
        guard self.state != .recording else { return }
        
        self.state = .recording
        
        setup(path: getFilename(), excluding: excluding) 
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
                print(self.writer!.outputURL)
                workspace.open(self.writer!.outputURL)
            } else if writer!.status == .failed {
                // Asset writing failed with an error
                if let error = writer!.error {
                    logger.error("Asset writing failed with error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Sets up both *writing* and *saving*
    ///
    /// Creates ``writer`` and ``input`` to write assets
    /// Sets up the stream to use ``self`` as `SCStreamOutput`
    func setup(path: String, excluding: [SCRunningApplication]) {
        Task(priority: .userInitiated){
            do{
                (self.writer, self.input) = try setupWriter(screen: screen, path: path)
                
                logger.log("Setup Asset Writer \(self.writer)")
                logger.log("Setup Asset Writer Input \(self.input)")
                
                try setupStream(screen: screen, showCursor: showCursor, excluding: excluding)
                
                logger.debug("Setup stream")
            } catch{
                logger.error("Failed to setup stream")
            }
        }
    }
    
    /// Sets up the `AVAssetWriter` and `AVAssetWriterInput`
    ///
    /// ``stream(_:didOutputSampleBuffer:of:)`` relies on this to save data
    func setupWriter(screen: SCDisplay, path: String) throws -> (AVAssetWriter, AVAssetWriterInput) {
        let settingsAssistant = AVOutputSettingsAssistant(preset: .hevc3840x2160)
        var settings = settingsAssistant!.videoSettings!
        
        logger.debug("\(settings.keys.debugDescription)") // shows the user some of the base settings
        
        let colorPropertySettings = [
            AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
            AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_2020,
            AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
        ]

        settings[AVVideoWidthKey] = screen.width
        settings[AVVideoHeightKey] = screen.height
        settings[AVVideoColorPropertiesKey] = colorPropertySettings
        
//        settings[AVVideoExpectedSourceFrameRateKey] = UserDefaults.standard.integer(forKey: "framesPerSecond")
        
        var url = URL(string: path, relativeTo: .temporaryDirectory)!
        
        if let location = UserDefaults.standard.url(forKey: "saveLocation"){
            url = URL(string: path, relativeTo: location)!
        } else {
            logger.error("Error: no screen save location present")
        }
        
        var fileType : AVFileType = baseConfig.validFormats.first!
        if let fileTypeValue = UserDefaults.standard.object(forKey: "format"),
           let preferenceType = fileTypeValue as? AVFileType{
            fileType = preferenceType
        }
        
        let writer = try AVAssetWriter(url: url, fileType: fileType)
                        
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = true
        
        writer.add(input)
        
        // timeMultiple setup -> for some reason, does not return optional
        timeMultiple = UserDefaults.standard.double(forKey: "timeMultiple")
                
        return (writer, input)
    }
    
    /// Creates an `SCStream` with correct `filter` and `configuration`. ``self`` is set to recieve this data
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
        config.queueDepth = 10
        config.colorSpaceName = CGColorSpace.extendedSRGB
        config.backgroundColor = .white
        
        stream = SCStream(
            filter: contentFilter,
            configuration: config,
            delegate: StreamDelegate()
        )
        
        guard let stream = stream else { return }
        
        try stream.addStreamOutput(
            self,
            type: .screen,
            sampleHandlerQueue: .global(qos: .userInitiated)
        )
        
        stream.startCapture(completionHandler: handleStreamStartFailure)
    }
    
    /// Generates a filename specific to `SCDisplay` and `CMTime`
    func getFilename() -> String {
        let randomValue = Int(arc4random_uniform(100_000)) + 1
        return "\(screen.displayID)-\(randomValue).mov"
    }
    
    /// Saves each `CMSampleBuffer` from the screen
    func stream(_ stream: SCStream, didOutputSampleBuffer: CMSampleBuffer, of: SCStreamOutputType) {
        guard self.state == .recording else { return }
        
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
    
    /// Receives a list of `CMSampleBuffers` and uses `shouldSaveVideo` to determine whether or not to save a video
    func handleVideo(buffer: CMSampleBuffer){
        guard self.input != nil else { // both
            logger.error("No AVAssetWriter with the name `input` is present")
            return
        }
        
        do{
            guard let attachmentsArray : NSArray = CMSampleBufferGetSampleAttachmentsArray(buffer,
                                                                                          createIfNecessary: false),
                  let attachments : NSDictionary = attachmentsArray.firstObject as? NSDictionary
            else {
                logger.error("Attachments Array does not work")
                return
            }
                                                                                                
            // the status needs to be not `.complete`
            guard let rawStatusValue = attachments[SCStreamFrameInfo.status] as? Int, let status = SCFrameStatus(rawValue: rawStatusValue), status == .complete else {
                return }
            
            guard let writer = self.writer, let input = self.input else {return}
            
            if writer.status == .unknown {
               writer.startWriting()
               offset = try buffer.sampleTimingInfos().first!.presentationTimeStamp
               writer.startSession(atSourceTime: offset)
               return
            }
            
            guard writer.status != .failed else {
                logger.log("Screen - failed")
                return
            }
                        
            input.append(try buffer.offsettingTiming(by: offset, multiplier: 1.0 / timeMultiple))
            logger.log("Appended buffer")
        } catch {
            logger.error("Invalid framebuffer")
        }
    }
    
    /// Uses the frame rate and duration to determine if the frame should be saved
    func shouldSaveVideo(buffer: CMSampleBuffer) -> Bool{
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
}

/// Defines behavior when the state of the `SCStream` changes.
///
/// Technically required, but less used in this instance
class StreamDelegate : NSObject, SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        logger.error("The stream stopped with \(error.localizedDescription)")
    }
}

