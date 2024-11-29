import AVFoundation
import Cocoa
import ScreenCaptureKit
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
  var apps: [SCRunningApplication: Bool] = [:]
  var showCursor: Bool = true

  // Recording timings
  var offset: CMTime = CMTime(seconds: 0.0, preferredTimescale: 60)
  var timeMultiple: Double = 1  // offset set based on settings
  var frameCount: Int = 0
  var frameChanged = true

  var lastAppendedFrame: CMTime = .zero
  var tmpFrameBuffer: CMSampleBuffer?

  var height: Int?
  var width: Int?

  override var description: String {
    if height == nil || width == nil {
      let pixelRatio = getPixelRatio(for: screen.displayID) ?? 1.0

      self.width = Int(CGFloat(screen.width) * pixelRatio)
      self.height = Int(CGFloat(screen.height) * pixelRatio)
    }

    return "[\(width ?? 0) x \(height ?? 0)] - Display \(screen.displayID)"
  }

  init(screen: SCDisplay, showCursor: Bool) {
    self.screen = screen
    self.showCursor = showCursor
  }

  // MARK: User Interaction
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

    while !input.isReadyForMoreMediaData {
      logger.log("Not able to mark the stream as finished")
      sleep(1)  // sleeping for a second
    }

    input.markAsFinished()
    writer.finishWriting { [self] in
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
        if let error = writer.error {
          logger.error("Asset writing failed with error: \(error.localizedDescription)")
          sendNotification(
            title: "Could not save asset", body: "\(error.localizedDescription)", url: nil)
        }
      }
    }
  }

  /// Sets up both *writing* and *saving*
  ///
  /// Creates ``writer`` and ``input`` to write assets
  /// Sets up the stream to use ``self`` as `SCStreamOutput`
  func setup(path: String, excluding: [SCRunningApplication]) {
    Task(priority: .userInitiated) {
      do {
        try setupStream(screen: screen, showCursor: showCursor, excluding: excluding)

        (self.writer, self.input) = try setupWriter(screen: screen, path: path)

        try await stream!.startCapture()

        logger.debug("Setup stream")
      } catch {
        logger.error("Failed to setup stream")
      }
    }
  }

  /// Sets up the `AVAssetWriter` and `AVAssetWriterInput`
  ///
  /// ``stream(_:didOutputSampleBuffer:of:)`` relies on this to save data
  func setupWriter(screen: SCDisplay, path: String) throws -> (AVAssetWriter, AVAssetWriterInput) {
    // TODO: Update this so hevc_displayP3 is not the assumed color space
    //
    // The display color space can easily be fetched dynamically using SCDisplay.CGDirectDisplayID
    //
    // see:
    // https://developer.apple.com/documentation/coregraphics/1454190-cgdisplaycopycolorspace

    // creates a custom-defined config for the P3 color space
    let config: VideoSettings = .hevcDisplayP3

    // uses a settings recommender to get the video settings
    let settingsAssistant = AVOutputSettingsAssistant(preset: config.preset)!

    let pixelRatio = getPixelRatio(for: screen.displayID) ?? 1.0
    let width = Int(CGFloat(screen.width) * pixelRatio)
    let height = Int(CGFloat(screen.height) * pixelRatio)

    settingsAssistant.sourceVideoFormat = try CMVideoFormatDescription(
      videoCodecType: .hevc, width: width, height: height)

    var settings = settingsAssistant.videoSettings!
    settings[AVVideoWidthKey] = width
    settings[AVVideoHeightKey] = height
    settings[AVVideoColorPropertiesKey] = config.colorProperties

    // more entropy in the video -> the higher the bitrate
    if var compressionProperties = settings[AVVideoCompressionPropertiesKey] as? [String: Any] {
      compressionProperties.removeValue(forKey: AVVideoAverageBitRateKey)
      compressionProperties[AVVideoQualityKey] = baseConfig.quality
      settings[AVVideoCompressionPropertiesKey] = compressionProperties
    }

    // Gets a valid file type, but replaces it if in preferences
    var fileType: AVFileType = baseConfig.validFormats.first!
    if let fileTypeValue = UserDefaults.standard.object(forKey: "format"),
      let preferenceType = fileTypeValue as? AVFileType
    {
      fileType = preferenceType
    }

    // Creates a valid url path (may not be user-specified)
    let url = getFileDestination(path: path)
    let writer = try AVAssetWriter(url: url, fileType: fileType)

    let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
    input.expectsMediaDataInRealTime = true

    writer.add(input)

    // timeMultiple setup -> for some reason, does not return optional
    timeMultiple = UserDefaults.standard.double(forKey: "timeMultiple")

    return (writer, input)
  }

  /// Creates an `SCStream` with correct `filter` and `configuration`. ``self`` is set to receive this data
  func setupStream(screen: SCDisplay, showCursor: Bool, excluding: [SCRunningApplication]) throws {
    let contentFilter = SCContentFilter(
      display: screen,
      excludingApplications: excluding,
      exceptingWindows: []
    )

    let pixelPointScale = Int(contentFilter.pointPixelScale)

    let config = SCStreamConfiguration()
    config.queueDepth = 20
    config.showsCursor = showCursor
    config.capturesAudio = false
    config.backgroundColor = .white

    // Set the width to twice the stated width (required for pixel ratio reasons)
    // required to get colors to look right
    // note: in the future, this **should not** be hard-coded
    config.width = screen.width * pixelPointScale
    config.height = screen.height * pixelPointScale

    // color settings
    // note: in display settings, you can set the color space. So, this should probably not be hard-coded either
    // source: https://support.apple.com/guide/mac-help/displays-settings-on-mac-mh40768
    config.colorSpaceName = CGColorSpace.displayP3
    config.pixelFormat = kCVPixelFormatType_ARGB2101010LEPacked

    if #available(macOS 14.0, *) {
      // Getting quality from user defaults
      if let qualityValue = UserDefaults.standard.object(forKey: "quality"),
        let quality = qualityValue as? QualitySettings
      {
        config.captureResolution = .nominal
      }

      config.streamName = "\(screen.displayID) Screen Recording"
      config.shouldBeOpaque = true  // Turns off transparency
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
  }

  /// Generates a filename specific to `SCDisplay` and `CMTime`
  func getFilename() -> String {
    return "display\(screen.displayID)-\(dateExtension)\(fileExtension)"
  }

  /// Saves each `CMSampleBuffer` from the screen
  func stream(_ stream: SCStream, didOutputSampleBuffer: CMSampleBuffer, of: SCStreamOutputType) {
    guard self.state == .recording else { return }

    switch of {
    case .screen:
      handleVideo(buffer: didOutputSampleBuffer)
    case .audio:
      logger.debug("Audio should not be captured")
    default:
      logger.error("Unknown future case")
    }
  }

  /// Receives a list of `CMSampleBuffers` and uses `appendBuffer` to save them
  func handleVideo(buffer: CMSampleBuffer) {
    guard self.input != nil else {  // both
      logger.error("No AVAssetWriter with the name `input` is present")
      return
    }

    guard
      let attachmentsArray: NSArray = CMSampleBufferGetSampleAttachmentsArray(
        buffer,
        createIfNecessary: false),
      let attachments: NSDictionary = attachmentsArray.firstObject as? NSDictionary
    else {
      logger.error("Attachments Array does not work")
      return
    }

    // the status needs to be not `.complete`
    guard let rawStatusValue = attachments[SCStreamFrameInfo.status] as? Int,
      let status = SCFrameStatus(rawValue: rawStatusValue), status == .complete
    else {
      return
    }

    guard let writer = self.writer else { return }

    // Start the writer if not started and use the current buffer's timestamp as a start point
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

    (tmpFrameBuffer, lastAppendedFrame, frameChanged) = appendBuffer(
      buffer: buffer, source: .screen)

    // Logs the frames
    frameCount += 1
    if frameCount % baseConfig.logFrequency == 0 {
      logger.log("\(self) Appended buffers \(self.frameCount)")
    }
  }
}

/// Defines behavior when the state of the `SCStream` changes.
///
/// Technically required, but less used in this instance
class StreamDelegate: NSObject, SCStreamDelegate {
  func stream(_ stream: SCStream, didStopWithError error: Error) {
    logger.error("The stream stopped with \(error.localizedDescription)")
  }
}

/// Gets the pixel ratio or `bakingScaleFactor` of the screen before starting recording
///
/// This is important because while Apple displays use a pixel ratio of 2.0, this may not be the case for
/// external monitors
func getPixelRatio(for displayID: CGDirectDisplayID) -> CGFloat? {
  guard
    let screens = NSScreen.screens.first(where: {
      guard
        let screenID = $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")]
          as? CGDirectDisplayID
      else {
        return false
      }
      return screenID == displayID
    })
  else {
    return nil
  }

  return screens.backingScaleFactor
}
