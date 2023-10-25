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
//    var adapter: AVAssetWriterInputPixelBufferAdaptor?
    
    let captureQue = DispatchQueue(label: "com.smartservices.captureQueue") // dispatch que does not work for some reason
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
                
                print(inputDevice.activeFormat)
                
                print("Active Format \(inputDevice.activeFormat)")
                print("Active Color Space \(inputDevice.activeColorSpace)")


                (self.writer, self.input) = try setupWriter(device: self.inputDevice, path: path)
                
                logger.log("Camera Setup Asset Writer \(self.writer)")
                logger.log("Camera Setup Asset Writer Input \(self.input)")
                
                // starts the stream
                self.captureSession!.startRunning()
                if self.captureSession!.isRunning{
                    print("session is running")
                }
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
                
        let url = URL(string: path, relativeTo: .temporaryDirectory)!
        
        if FileManager.default.isDeletableFile(atPath: url.path) {
                    print("Could delted the file")
            _ = try? FileManager.default.removeItem(atPath: url.path)
                }
        
        let rootFolderURL = try FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
        )[0].appendingPathComponent(path, conformingTo: .mpeg4Movie)

        logger.debug("URL: \(rootFolderURL)")
        logger.debug("Path: \(path)")
        
        let writer = try AVAssetWriter(outputURL: rootFolderURL, fileType: .mp4)
   
                    
        print("Camera Writer Settings \(settings)")
        print("Base settings \(baseConfig.videoSettings)")
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = true
        writer.shouldOptimizeForNetworkUse = true

        guard writer.canAdd(input) else {
            print("Can't add input")
            return (writer, input)
        }
        writer.add(input)
        
        return (writer, input)
    }
    
    /// Setting up stream
    func setupStream(device: AVCaptureDevice) throws {
        let captureSession = AVCaptureSession()
        let cameraInput = try AVCaptureDeviceInput(device: self.inputDevice)

        
        print("Session Preset \(captureSession.sessionPreset)")
      
        
        print(self.inputDevice.formats)
        print(self.inputDevice.activeFormat)
        
        if captureSession.canAddInput(cameraInput) {
            logger.log("Added input")
            captureSession.addInput(cameraInput)
        }
        
        // Adding the output to the camera session
        videoOutput = AVCaptureVideoDataOutput()
//        videoOutput?.automaticallyConfiguresOutputBufferDimensions = false -> unavailable in macos
        
        guard let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) else {
            logger.error("Can't add video output")
            return
        }
    
        captureSession.addOutput(videoOutput)
        captureSession.beginConfiguration()
        
        captureSession.sessionPreset = .high
        
        
        videoOutput.setSampleBufferDelegate(self, queue: .global(qos: .userInitiated))

        
//        videoOutput.videoSettings = nil
        
        
        videoOutput.videoSettings = videoOutput.recommendedVideoSettings(forVideoCodecType: .h264, assetWriterOutputFileType: .mp4)!
            
        
//        videoOutput.videoSettings = videoOutput.recommendedVideoSettingsForAssetWriter(writingTo: <#T##AVFileType#>)
        
        print(videoOutput.videoSettings)
        print(videoOutput)
        
        print("Pixel format type key")
        print(kCVPixelBufferPixelFormatTypeKey)
        
        print(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
        let settings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: 875704422,
            kCVPixelBufferWidthKey as String: 1920,
            kCVPixelBufferHeightKey as String: 1080,
            AVVideoScalingModeKey: AVVideoScalingModeFit,
            AVVideoCodecKey: AVVideoCodecType.h264,
//            AVVideoEncoderSpecificationKey: kVTEncodeFrameOptionKey_AcknowledgedLTRTokens,
        ]
        
        videoOutput.videoSettings = settings

//        videoOutput.videoSettings = nil
//        videoOutput.alwaysDiscardsLateVideoFrames = true
//        videoOutput.videoSettings
        
        print(videoOutput.availableVideoPixelFormatTypes)
        print(videoOutput.availableVideoCodecTypesForAssetWriter(writingTo: .mp4))
        print(videoOutput.attributeKeys)
        print(captureSession.inputs)
        print(captureSession.outputs)
        
        print(cameraInput.attributeKeys)
//        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        print("Video Settings: \(videoOutput.videoSettings)")
        
        print(videoOutput.sampleBufferDelegate)

        captureSession.commitConfiguration()
        
//        videoOutput.setSampleBufferDelegate(self, queue: captureQue)

        
        self.captureSession = captureSession
        self.cameraInput = cameraInput
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
    
        guard let input = input, let writer = writer else {
            logger.log("Either the input or the writer is null")
            return
        }
    // Same as screen
    while(!(input.isReadyForMoreMediaData ?? false)){
        logger.log("Not able to mark the stream as finished")
        sleep(1) // sleeping for a second
    }
    
    input.markAsFinished() // this is good
    writer.finishWriting { [self] in
        if writer.status == .completed {
            // Asset writing completed successfully
            print(writer.outputURL)
            workspace.open(writer.outputURL)
        } else if writer.status == .failed {
            // Asset writing failed with an error
            if let error = writer.error {
                logger.error("Asset writing failed with error: \(String(describing: error))")
            }
        }
    }
}
    
    // MARK: -Streaming
    
    /// Equivalent to `stream` for `Screen`. Takes sample buffers and processes them
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // do not step in without being locked
        print("Initial sample buffer")
        print(sampleBuffer)
        
        print("Connection \(connection)")
        print("Output \(output)")
        
        
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
        print("Decode \(buffer.decodeTimeStamp)")
        print(CMSampleBufferGetDataBuffer(buffer))
        print(CMSampleBufferGetImageBuffer(buffer))
        
        guard let input = self.input, let writer = self.writer else {
            print("Not video writer present")
            return
        }
        
        if writer.status != .failed {
            print("Writer has NOT failed")
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
//        buffer = (try! buffer.singleSampleBuffers())
        

        do {
            try buffer.makeDataReady()
        } catch {
            print("Trying to make data ready")
            return
        }
//        let newBuffer = (try! buffer.singleSampleBuffers())


        print("Sample Buffer\(buffer)")
        if writer.status == .unknown {
            // set the timescale of the input
//            input.mediaTimeScale = buffer.presentationTimeStamp.timescale
            
            if !writer.startWriting() {
                print("Writer had an error while starting \(writer.error)")
            }
            writer.startSession(atSourceTime: buffer.decodeTimeStamp)
            if input.append(buffer) {
                
                print(input.canPerformMultiplePasses)
                print("Was able to append the first buffer")
            } else {
                print(buffer)
                print("Was not able to append the first buffer")
            }
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
        
//        if adapter!.append(imageBuffer, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(buffer)){
//            print("Was able to release image buffer")
//        } else {
//            print("Was not able to use image buffer")
//        }
        
//        if canAddSampleBuffer(buffer: buffer, assetWriterInput: input) {
//
//            if input.append(buffer) {
//                print("Appended successfully")
//            } else {
//                print("Append failed")
//            }
//            print("ADDED Buffer")
//        }
        
        print(CMSampleBufferGetDataBuffer(buffer))
        if input.append(buffer) {
            print("Appended Buffer Successfully")
        } else {
            print("Append failed now ")
        }
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
