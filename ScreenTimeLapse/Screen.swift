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
    var showCursor: Bool = true
    
    // Recording timings
    var offset: CMTime = CMTime(seconds: 0.0, preferredTimescale: 60)
    var timeMultiple: Double = 1 // offset set based on settings
    var frameCount: Int = 0
    
    var lastAppenedFrame: CMTime = .zero
    var tmpFrameBuffer: CMSampleBuffer?
    
    override var description: String {
        "[\(screen.width) x \(screen.height)] - Display \(screen.displayID)"
    }
    
    init(screen: SCDisplay, showCursor: Bool) {
        self.screen = screen
    }
    
    // MARK: -User Interaction
    func startRecording(excluding: [SCRunningApplication], showCursor: Bool) {
        guard self.enabled else { return }
        guard self.state != .recording else { return }
        
        self.showCursor = showCursor
        
        self.state = .recording
        
        setup(path: getFilename(), excluding: excluding)
    }
    
    func pauseRecording() {
        self.state = .paused
    }
    
    func resumeRecording() {
        self.state = .recording
    }
 
    /// Saves recording and stops `stream`
    func saveRecording() {
        guard self.enabled else { return }
        
        guard let writer = writer, let input = input else { return }
        
        self.state = .stopped
        
        logger.log("Screen -- saved recording")
        
        if let stream = stream {
            stream.stopCapture()
        }
        
        while(!input.isReadyForMoreMediaData){
            logger.log("Not able to mark the stream as finished")
            sleep(1) // sleeping for a second
        }
        
        input.markAsFinished()
        writer.finishWriting { [self] in
            if writer.status == .completed {
                // Asset writing completed successfully
                
                if UserDefaults.standard.bool(forKey: "showAfterSave"){
                    workspace.open(writer.outputURL)
                }
                
                sendNotification(title: "\(self) saved", body: "Saved video")
                
                logger.log("Saved video to \(writer.outputURL.absoluteString)")
            } else if writer.status == .failed {
                // Asset writing failed with an error
                if let error = writer.error {
                    logger.error("Asset writing failed with error: \(error.localizedDescription)")
                    sendNotification(title: "Could not save asset", body: "\(error.localizedDescription)")
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
        let config : VideoSettings = .hevc_displayP3
        
        let settingsAssistant = AVOutputSettingsAssistant(preset: config.preset)!
        
        settingsAssistant.sourceVideoFormat = try CMVideoFormatDescription(videoCodecType: .hevc, width: screen.width * 2, height: screen.height * 2)
        
        var settings = settingsAssistant.videoSettings!
        
        
        settings[AVVideoWidthKey] = screen.width * 2
        settings[AVVideoHeightKey] = screen.height * 2
        settings[AVVideoColorPropertiesKey] = config.colorProperties
//        settings[kCVPixelBufferPixelFormatTypeKey as String] = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
//        settings["SASdfasdf"] = 1231
        print(settings)
        
        // TODO: check if the pixel buffer makes sense
        
        //        settings[AVVideoExpectedSourceFrameRateKey] = UserDefaults.standard.integer(forKey: "framesPerSecond")
        
        var fileType : AVFileType = baseConfig.validFormats.first!
        if let fileTypeValue = UserDefaults.standard.object(forKey: "format"),
           let preferenceType = fileTypeValue as? AVFileType{
            fileType = preferenceType
        }
        
        let url = getFileDestination(path: path)
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
        config.streamName = "\(screen.displayID) Screen Recording"
        config.queueDepth = 20
        config.width = screen.width * 2
        config.height = screen.height * 2
        config.showsCursor = showCursor
        config.capturesAudio = false
        config.backgroundColor = .white
        config.shouldBeOpaque = true
        
        // color settings
        config.colorSpaceName = CGColorSpace.displayP3
        config.pixelFormat = kCVPixelFormatType_ARGB2101010LEPacked
        
        // Gettings quality from user defaults
        if let qualityValue = UserDefaults.standard.object(forKey: "quality"),
           let quality = qualityValue as? QualitySettings {
            config.captureResolution = switch quality {
            case .high : SCCaptureResolutionType.best
            case .medium : SCCaptureResolutionType.automatic
            case .low : SCCaptureResolutionType.nominal
            }
        }
        
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
        
        guard let writer = self.writer else {return}
        
        if writer.status == .unknown {
            writer.startWriting()
            offset = buffer.presentationTimeStamp
            writer.startSession(atSourceTime: offset)
            return
        }
        
        guard writer.status != .failed else {
            logger.log("Screen - failed")
            return
        }
        
        (tmpFrameBuffer, lastAppenedFrame) = appendBuffer(buffer: buffer)
        
        frameCount += 1
        if frameCount % baseConfig.logFrequency == 0 {
            logger.log("\(self) Appended buffers \(self.frameCount)")
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

