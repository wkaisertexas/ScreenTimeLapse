import AVFoundation

/// Records the output of a camera in a stream-like format
class Camera: NSObject {
    var state: RecordingState = .stopped
    var metaData: OutputInfo = OutputInfo()
    var enabled: Bool = false
    var writer: AVAssetWriter?
    var input: AVAssetWriterInput?
    var lastSavedFrame: CMTime?
    
    // Audio Video Capture-Specific Functionality
    var inputDevice: AVCaptureDevice
    
    var recordVideo: RecordVideo?

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
    
    // doing things
    func stopRecording(){
        //
    }
    
    func setup(path: String) {
        Task(priority: .userInitiated){ [self] in // does doing this in a task fuck things up
            do{
                try setupStream(device: self.inputDevice)
                                
//                (self.writer, self.input) = try setupWriter(device: self.inputDevice, path: path)

                // starts the stream
//                self.captureSession!.startRunning()
            } catch{
                logger.error("Failed to setup stream")
            }
        }
    }
    
    /// Sets up the `AVAssetWriter` and `AVAssetWriterInput`
    func setupWriter(device: AVCaptureDevice, path: String) throws -> (AVAssetWriter, AVAssetWriterInput){
        let url = URL(string: path, relativeTo: .temporaryDirectory)!
        
        let rootFolderURL = try FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
        )[0].appendingPathComponent(path, conformingTo: .mpeg4Movie)

        let writer = try AVAssetWriter(outputURL: rootFolderURL, fileType: .mp4)
   
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: baseConfig.videoSettings)
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
    func setupStream(device: AVCaptureDevice) {
    }
    
    // MARK: -User Interaction
    func startRecording() {
        guard self.enabled else { return }
        guard self.state != .recording else { return }
        logger.log("Camera Recording")
        
        self.state = .recording
        
        self.recordVideo = RecordVideo(device: inputDevice, callback: handleVideo)
        
        // create a recording object
//        setup(path: getFilename()) // TODO: implement logic which actually gets the excluding
    }
    
    func saveRecording() {
    guard self.enabled else { return }
    
    self.state = .stopped
     
    logger.log("Screen -- saved recording")
    
//    if let captureSession = captureSession {
//        captureSession.stopRunning()
//        print("Stopped running")
//    }
//
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
    func handleVideo(buffer: CMSampleBuffer){
        print("Handle video in proper camera \(buffer)")
    }
    
//    func handleVideo(buffer: CMSampleBuffer){
//        guard let input = self.input, let writer = self.writer else {
//            print("Not video writer present")
//            return
//        }
//
//        if writer.status == .failed {
//            print("Writer has failed")
//            return
//        }
//
//        guard buffer.isValid else {
//            logger.log("Invalid Camera Buffer")
//            return
//        }
//
//        print("Sample Buffer\(buffer)")
//        if writer.status == .unknown {
//            // set the timescale of the input
////            input.mediaTimeScale = buffer.presentationTimeStamp.timescale
//
//            if !writer.startWriting() {
//                print("Writer had an error while starting \(writer.error)")
//            }
////            writer.startSession(atSourceTime: buffer.decodeTimeStamp)
//            writer.startSession(atSourceTime: .zero)
//            if input.append(buffer) {
//                print("Was able to append the first buffer")
//            } else {
//                print(buffer)
//                print("Was not able to append the first buffer")
//            }
//            return
//        }
//
//        guard writer.status == .writing else {
//            print("The writer has failed \(String(describing: writer.error!))")
//            return
//        }
//
//        guard input.isReadyForMoreMediaData else {
//            print("Is not ready for more data")
//            return
//        }
//
//        if input.append(buffer) {
//            print("Appended Buffer Successfully")
//        } else {
//            print("Append failed now ")
//        }
//    }
    
    /// Generates a random filename
    func getFilename() -> String {
        let randomValue = Int(arc4random_uniform(100_000)) + 1
        return "\(randomValue).mp4"
    }
}

