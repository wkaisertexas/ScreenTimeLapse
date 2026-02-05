import AVFoundation
import SwiftUI

/// Records the output of a `AVCaptureDevice` in a stream-like format
class Camera: NSObject, Recordable {
  var state: RecordingState = .stopped
  var metaData: OutputInfo = OutputInfo()
  var enabled: Bool = false
  var writer: AVAssetWriter?
  var input: AVAssetWriterInput?

  // Audio Video Capture-Specific Functionality
  var inputDevice: AVCaptureDevice
  var recordVideo: RecordVideo?

  // Time Synchronization
  var offset: CMTime = CMTime(seconds: 0.0, preferredTimescale: 60)
  var timeMultiple: Double = 1  // offset set based on settings
  var frameCount: Int = 0
  var frameChanged = true

  var lastAppendedFrame: CMTime = .zero
  var tmpFrameBuffer: CMSampleBuffer?
  var sessionStartDate: Date?
  
  // Flag to prevent starting new recording while previous is finalizing
  private var isFinalizingRecording = false

  override var description: String {
    if inputDevice.manufacturer.isEmpty {
      return "\(self.inputDevice.localizedName)"
    } else {
      return "\(self.inputDevice.localizedName) - \(inputDevice.manufacturer)"
    }
  }

  init(camera: AVCaptureDevice) {
    self.inputDevice = camera
  }

  func setup(path: String) {
    Task(priority: .userInitiated) { [self] in  // does doing this in a task fuck things up
      do {
        self.recordVideo = RecordVideo(device: inputDevice, callback: handleVideo)  // minimal

        (self.writer, self.input) = try setupWriter(device: self.inputDevice, path: path)

        self.recordVideo?.startRunning()
      } catch {
        logger.error("Failed to setup stream")
      }
    }
  }

  /// Sets up the `AVAssetWriter` and `AVAssetWriterInput`
  func setupWriter(device: AVCaptureDevice, path: String) throws -> (
    AVAssetWriter, AVAssetWriterInput
  ) {
    let url = getFileDestination(path: path)

    let videoSettings = VideoSettings.hevcDisplayP3

    let settingsAssistant = AVOutputSettingsAssistant(preset: videoSettings.preset)!
    var settings = settingsAssistant.videoSettings!

    // Setting up the camera with correct color
    let dimensions = device.activeFormat.formatDescription.dimensions
    settings[AVVideoWidthKey] = dimensions.width
    settings[AVVideoHeightKey] = dimensions.height
    settings[AVVideoColorPropertiesKey] = videoSettings.colorProperties

    var fileType: AVFileType = baseConfig.validFormats.first!
    if let fileTypeValue = UserDefaults.standard.object(forKey: "format"),
      let preferenceType = fileTypeValue as? AVFileType
    {
      fileType = preferenceType
    }

    let writer = try AVAssetWriter(outputURL: url, fileType: fileType)

    let input: AVAssetWriterInput
    if TimestampOverlay.shouldUseOverlayFormat(for: .camera),
      let formatHint = TimestampOverlay.formatDescription32BGRA(
        width: Int(dimensions.width),
        height: Int(dimensions.height)
      )
    {
      input = AVAssetWriterInput(
        mediaType: .video,
        outputSettings: settings,
        sourceFormatHint: formatHint
      )
    } else {
      input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
    }
    input.expectsMediaDataInRealTime = true

    guard writer.canAdd(input) else {
      logger.error("Can't add input")
      return (writer, input)
    }
    writer.add(input)

    // how much faster or slower the recording show be
    timeMultiple = UserDefaults.standard.double(forKey: "timeMultiple")

    return (writer, input)
  }

  // MARK: User Interaction
  func startRecording() {
    guard self.enabled else { return }
    guard self.state != .recording else { return }
    guard !isFinalizingRecording else {
      logger.warning("Cannot start recording while previous recording is being finalized")
      return
    }
    logger.log("\(self.description) Recording")

    // Reset state for new recording
    resetRecordingState()
    
    self.state = .recording

    setup(path: getFilename())
  }
  
  /// Resets all state variables for a new recording session
  private func resetRecordingState() {
    // Clean up old objects
    if let oldRecordVideo = recordVideo, oldRecordVideo.isRecording() {
      oldRecordVideo.stopSession()
    }
    recordVideo = nil
    writer = nil
    input = nil
    
    // Reset time synchronization
    offset = CMTime(seconds: 0.0, preferredTimescale: 60)
    frameCount = 0
    frameChanged = true
    lastAppendedFrame = .zero
    tmpFrameBuffer = nil
    sessionStartDate = nil
  }

  func saveRecording() {
    guard self.enabled else { return }

    self.state = .stopped
    self.isFinalizingRecording = true

    logger.log("Camera - saved recording")

    if let recorder = recordVideo, recorder.isRecording() {
      recorder.stopSession()
      logger.log("Stopped capture session")
    }

    guard let input = input, let writer = writer else {
      logger.log("Either the input or the writer is null")
      self.isFinalizingRecording = false
      return
    }
    
    // Check if writer is in a valid state to finish
    guard writer.status == .writing else {
      logger.error("Writer is not in writing state, status: \(writer.status.rawValue)")
      self.isFinalizingRecording = false
      return
    }

    // Same as screen
    while !input.isReadyForMoreMediaData {
      logger.error("Not able to mark the stream as finished")
      sleep(1)  // sleeping for a second
    }

    input.markAsFinished()
    writer.finishWriting { [self] in
      defer {
        // Always reset the flag when finalization is complete
        self.isFinalizingRecording = false
      }
      
      if writer.status == .completed {
        // Asset writing completed successfully
        if UserDefaults.standard.bool(forKey: "showAfterSave")
          || writer.outputURL.isInTemporaryFolder()
        {
          workspace.open(writer.outputURL)
        }

        sendNotification(title: "\(self) saved", body: "Saved video", url: writer.outputURL)

        logger.log("Saved video to \(writer.outputURL.absoluteString)")
      } else if writer.status == .failed {
        // Asset writing failed with an error
        guard let error = writer.error else { return }

        logger.error("Asset writing failed with error: \(String(describing: error))")
        sendNotification(
          title: "Could not save asset", body: "\(error.localizedDescription)", url: nil)
      }
    }
  }

  // MARK: Streaming
  func handleVideo(buffer: CMSampleBuffer) {
    // Ignore frames during finalization or when not recording
    guard state == .recording, !isFinalizingRecording else {
      return
    }
    
    guard let input = self.input, let writer = self.writer else {
      // Only log if we're actually supposed to be recording
      if state == .recording {
        logger.error("Not video writer present")
      }
      return
    }

    guard writer.status != .failed else {
      logger.error("Writer has failed")
      return
    }

    guard buffer.isValid else {
      logger.error("Invalid Camera Buffer")
      return
    }

    if writer.status == .unknown {
      self.offset = buffer.presentationTimeStamp
      sessionStartDate = Date()

      writer.startWriting()
      writer.startSession(atSourceTime: self.offset)

      if let start = sessionStartDate,
        let overlaid = TimestampOverlay.apply(to: buffer, displayTime: start, source: .camera)
      {
        input.append(overlaid)
      } else {
        input.append(buffer)
      }
      return
    }

    guard writer.status == .writing else {
      logger.error("The writer has failed \(String(describing: writer.error!))")
      return
    }

    guard input.isReadyForMoreMediaData else {
      logger.error("Is not ready for more data")
      return
    }

    (tmpFrameBuffer, lastAppendedFrame, frameChanged) = appendBuffer(
      buffer: buffer, source: .camera)

    // log frame count
    frameCount += 1
    if frameCount % baseConfig.logFrequency == 0 {
      let logMessage: String = "\(self) Appended Buffer \(frameCount)"
      logger.log("\(logMessage)")
    }
  }

  /// Generates a filename with the device name and current date
  func getFilename() -> String {
    return "\(inputDevice.localizedName)\(dateExtension)\(fileExtension)"
  }
}
