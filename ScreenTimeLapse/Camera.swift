import Foundation
import AVFoundation

var frameNumber = 0
/// Records the output of a camera in a stream-like format
class Camera: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, Recordable {
    var state: RecordingState = .stopped
    var metaData: OutputInfo = OutputInfo()
    var enabled: Bool = false
    var writer: AVAssetWriter?
    var input: AVAssetWriterInput?
    var lastSavedFrame: CMTime?
    
    // Audio Video Capture-Specific Functionality
    var inputDevice: AVCaptureDevice
    var captureSession: AVCaptureSession?
    var connection: AVCaptureConnection?
    var cameraInput: AVCaptureDeviceInput?
    var videoOutput: AVCaptureVideoDataOutput?
    
    let captureQue = DispatchQueue(label: "com.smartservices.captureQueue")
    let processingGroup = DispatchGroup()

    
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
        Task(priority: .userInitiated){
            do{
                try setupStream(device: self.inputDevice)
                
                logger.debug("Setup stream")
                
                
                print("Active Format \(inputDevice.activeFormat)")
                print("Active Color Space \(inputDevice.activeColorSpace)")

                
                (self.writer, self.input) = try setupWriter(device: self.inputDevice, path: path)
                
                logger.log("Camera Setup Asset Writer \(self.writer)")
                logger.log("Camera Setup Asset Writer Input \(self.input)")
                
                // starts the stream
                self.captureSession?.startRunning()
            } catch{
                logger.error("Failed to setup stream")
            }
        }
    }
    
    /// Sets up the `AVAssetWriter` and `AVAssetWriterInput`
    func setupWriter(device: AVCaptureDevice, path: String) throws -> (AVAssetWriter, AVAssetWriterInput){
//        let settingsAssistant = AVOutputSettingsAssistant(preset: .hevc3840x2160)
//        var settings = settingsAssistant!.videoSettings!
        
        var settings = videoOutput!.recommendedVideoSettingsForAssetWriter(writingTo: .mp4)!
        print("Video Settings just recommended: \(settings)")
//        var settings : [String: Any] = [
//            AVVideoWidthKey: 1920,
//            AVVideoHeightKey: 1080,
//            AVVideoCodecKey: AVVideoCodecType.h264
//        ]

//        settings[AVVideoWidthKey] = 1920
//        settings[AVVideoHeightKey] = 1080
//        settings[AVVideoCodecKey] = AVVideoCodecType.hevc
        
//
//        if let activeFormat = inputDevice.activeFormat {
//            let formatDescription = activeFormat..formatDescription
//                if let formatDescription = formatDescription {
//                    let pixelFormat = CMFormatDescriptionGetMediaSubType(formatDescription)
//                    // Store pixelFormat for later use
//                    print("Set pixel format to \(pixelFormat) \(Int(pixelFormat))")
//                    settings[ kCVPixelBufferPixelFormatTypeKey as String] = Int(pixelFormat)
//                }
//            }
//        settings[kCVPixelBufferPixelFormatTypeKey as String] = Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
        
        print("Output of inputs")
        print(settings)
        
        print(AVVideoCodecType.h264)
        
//        let url = URL(string: path, relativeTo: .desktopDirectory)!
        
        let rootFolderURL = try FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
//                    appropriateFor: nil,
//                    create: false
        )[0].appendingPathComponent(path, conformingTo: .mpeg4Movie)

        logger.debug("URL: \(rootFolderURL)")
        logger.debug("Path: \(path)")
        
        let writer = try AVAssetWriter(url: rootFolderURL, fileType: .mp4)
                        
        print("Camera Writer Settings \(settings)")
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = true
        
        guard writer.canAdd(input) else {
            print("Can't add input")
            return (writer, input)
        }
        writer.add(input)
        
//        writer.outputFileTypeProfile = AVFileTypeProfile.mpeg4AppleHLS
//        writer.preferredOutputSegmentInterval = CMTime(seconds: Double(6), preferredTimescale: 1)
                    
        return (writer, input)
    }
    
    /// Setting up stream
    func setupStream(device: AVCaptureDevice) throws {
        let captureSession = AVCaptureSession()
        print(captureSession.sessionPreset)
        
      
        let cameraInput = try AVCaptureDeviceInput(device: self.inputDevice)
    

        if captureSession.canAddInput(cameraInput) {
            logger.log("Added input")
            captureSession.addInput(cameraInput)
        }
        self.cameraInput = cameraInput
        self.captureSession = captureSession
        
        // Adding the output to the camera session
        videoOutput = AVCaptureVideoDataOutput()
        
        if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            

//            var settings : [String: Any] = [AVVideoCodecKey:  AVVideoCodecType.hevc] // videoOutput.recommendedVideoSettings(forVideoCodecType: ., assetWriterOutputFileType: .mp4)!
            
//            settings[] =
            
//            videoOutput.videoSettings = settings
            
            videoOutput.videoSettings = videoOutput.recommendedVideoSettings(forVideoCodecType: .h264, assetWriterOutputFileType: .mp4)!
            
            print("Video Settings: \(videoOutput.videoSettings)")
            if let connection = videoOutput.connection(with: .video) {
                connection.videoMinFrameDuration = CMTimeMake(value: 1, timescale: 30)
            }
        }
        videoOutput!.setSampleBufferDelegate(self, queue: .global(qos: .userInitiated))
        
        self.captureSession = captureSession
    }
    
    // MARK: -User Interaction
    func startRecording() {
        guard self.enabled else { return }
        guard self.state != .recording else { return }
        logger.log("Camera Recording")
        
        self.state = .recording
        setup(path: getFilename()) // TODO: implement logic which actually gets the excluding
    }
    
    func saveRecording() {
    guard self.enabled else { return }
    
    self.state = .stopped
     
    logger.log("Screen -- saved recording")
    
    if let captureSession = captureSession {
        captureSession.stopRunning()
        print("Stopped running")
    }
        
    // Same as screen
    while(!(input?.isReadyForMoreMediaData ?? false)){
        logger.log("Not able to mark the stream as finished")
        sleep(1) // sleeping for a second
    }
    
    input!.markAsFinished() // this is good
    writer!.finishWriting { [self] in
        if self.writer!.status == .completed {
            // Asset writing completed successfully
            print(self.writer!.outputURL)
            workspace.open(self.writer!.outputURL)
        } else if writer!.status == .failed {
            // Asset writing failed with an error
            if let error = writer!.error {
                logger.error("Asset writing failed with error: \(String(describing: error))")
            }
        }
    }
}
    
    // MARK: -Streaming
    
    /// Equivalent to `stream` for `Screen`. Takes sample buffers and processes them
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // do not step in without being locked
        
        
        processingGroup.enter()
                
                // Process the sample buffer asynchronously on the capture queue
        captureQue.async { [self] in
            print(frameNumber)
                    frameNumber += 1
                    // Your processing code here
                    if let videoDataOutput = output as? AVCaptureVideoDataOutput {
                        handleVideo(buffer: sampleBuffer)
                    } else {
                        print("Non video data present")
                    }
                    
                    // Signal that processing is complete for this frame or sample
                    processingGroup.leave()
                }
                
                // Wait for the current frame's processing to complete before the next one
                processingGroup.wait()
        
           
    }
    
    // TODO: Remove and consolodate `handleVideo`
    func handleVideo(buffer: CMSampleBuffer){
        guard let input = self.input, let writer = self.writer else {
            print("Not video writer present")
            return
        }
        
        if writer.status != .failed {
            print("Writer has not failed")
        }
                
//        guard let attachmentsArray : NSArray = CMSampleBufferGetSampleAttachmentsArray(buffer,
//                                                                                      createIfNecessary: false),
//        var attachments : NSDictionary = attachmentsArray.firstObject as? NSDictionary
//        else {
//            logger.error("Attachments Array does not work")
//            return
//        }
        
//        print("Attachments \(attachments)")
        guard buffer.isValid else {
            logger.log("Invalid Camera Buffer")
            return
        }
        
//        buffer = (try! buffer.singleSampleBuffers()).

//        do {
//            try buffer.makeDataReady()
//        } catch {
//            print("Trying to make data ready")
//            return
//        }

        print("Sample Buffer\(buffer)")
        if writer.status == .unknown {
            writer.startWriting()
            writer.startSession(atSourceTime: .zero)
            return
        }
        
        guard writer.status == .writing else {
            print("The writer has failed \(String(describing: writer.error!))")
            return
        }

        guard input.isReadyForMoreMediaData else {
            print("Is not ready for more data")
            return
        }
//
//        let timeStamp = CMSampleBufferGetPresentationTimeStamp(buffer)
//        let seconds = CMTimeGetSeconds(timeStamp)
//        print("Frame Time: \(seconds) seconds")
        
        if canAddSampleBuffer(buffer: buffer, assetWriterInput: input) {
            input.append(buffer)
        }
//
//        print("Output settings \(self.input!.outputSettings)")
//        
//        print("more settings \(self.input!.currentPassDescription)")
    }
    
    /// Generates a random filename
    func getFilename() -> String {
        let randomValue = Int(arc4random_uniform(100_000)) + 1
        return "\(randomValue).mp4"
    }
}

func CMTimeFromTimeInterval (_ timeInterval: TimeInterval) -> CMTime {
    return CMTime(seconds: timeInterval, preferredTimescale: 1_000_000)
}
