import AVFoundation
import SwiftUI

/// Records the output of a `AVCaptureDevice` in a stream-like format
class Camera: NSObject, Recordable {
    var state: RecordingState = .stopped
    var metaData: OutputInfo = OutputInfo()
    var enabled: Bool = false
    var writer: AVAssetWriter?
    var input: AVAssetWriterInput?
    var lastSavedFrame: CMTime?
    
    // Audio Video Capture-Specific Functionality
    var inputDevice: AVCaptureDevice
    var recordVideo: RecordVideo?
    
    // Offset
    var offset: CMTime = CMTime(seconds: 0.0, preferredTimescale: 60)
    var timeMultiple: Double = 1 // offset set based on settings
    var frameCount: Int = 0
    
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
        Task(priority: .userInitiated){ [self] in // does doing this in a task fuck things up
            do{
                self.recordVideo = RecordVideo(device: inputDevice, callback: handleVideo) // minimal
                
                (self.writer, self.input) = try setupWriter(device: self.inputDevice, path: path)
                
                self.recordVideo?.startRunning()
            } catch{
                logger.error("Failed to setup stream")
            }
        }
    }
    
    /// Sets up the `AVAssetWriter` and `AVAssetWriterInput`
    func setupWriter(device: AVCaptureDevice, path: String) throws -> (AVAssetWriter, AVAssetWriterInput){
        let url = getFileDestination(path: path)
        
        let settingsAssistant = AVOutputSettingsAssistant(preset: .hevc7680x4320)
        var settings = settingsAssistant!.videoSettings!
        
        // getting and setting the frame rate
        //        settings[AVVideoExpectedSourceFrameRateKey] = UserDefaults.standard.integer(forKey: "framesPerSecond")
        
        let dimensions = device.activeFormat.formatDescription.dimensions
        settings[AVVideoWidthKey] = dimensions.width
        settings[AVVideoHeightKey] = dimensions.height
        settings[AVVideoColorPropertiesKey] = [
            AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
            AVVideoColorPrimariesKey: AVVideoColorPrimaries_P3_D65,
            AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
        ]
        
        var fileType : AVFileType = baseConfig.validFormats.first!
        if let fileTypeValue = UserDefaults.standard.object(forKey: "format"),
           let preferenceType = fileTypeValue as? AVFileType{
            fileType = preferenceType
        }
        
        let writer = try AVAssetWriter(outputURL: url, fileType: fileType)
        
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = true
        
        guard writer.canAdd(input) else {
            print("Can't add input")
            return (writer, input)
        }
        writer.add(input)
        
        // timing offset
        timeMultiple = UserDefaults.standard.double(forKey: "timeMultiple")
        
        return (writer, input)
    }
    
    // MARK: -User Interaction
    func startRecording() {
        guard self.enabled else { return }
        guard self.state != .recording else { return }
        logger.log("\(self.description) Recording")
        
        self.state = .recording
        
        setup(path: getFilename())
    }
    
    func saveRecording() {
        guard self.enabled else { return }
        
        self.state = .stopped
        
        logger.log("Camera - saved recording")
        
        if let recorder = recordVideo, recorder.isRecording() {
            recorder.stopSession()
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
    func handleVideo(buffer: CMSampleBuffer){
        guard let input = self.input, let writer = self.writer else {
            print("Not video writer present")
            return
        }
        
        guard writer.status != .failed else {
            print("Writer has failed")
            return
        }
        
        guard buffer.isValid else {
            logger.log("Invalid Camera Buffer")
            return
        }
        
        if writer.status == .unknown {
            self.offset = buffer.presentationTimeStamp
            
            writer.startWriting()
            writer.startSession(atSourceTime: self.offset)
            
            input.append(buffer)
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
        
        if input.append(try! buffer.offsettingTiming(by: offset, multiplier: 1.0 / timeMultiple)) {
            frameCount += 1
            if frameCount % baseConfig.logFrequency == 0 {
                logger.log("\(self) Appended Buffer \(self.frameCount)")
            }
        } else {
            print("Append camera failed now ")
        }
    }
    
    /// Generates a random filename
    func getFilename() -> String {
        let randomValue = Int(arc4random_uniform(100_000)) + 1
        return "\(randomValue).mov"
    }
}

