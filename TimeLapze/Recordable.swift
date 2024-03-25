import AVFoundation
import ScreenCaptureKit
import UserNotifications

/// Represents an object interactable with a ``RecorderViewModel``
protocol Recordable: CustomStringConvertible {
  var metaData: OutputInfo { get set }
  var state: RecordingState { get set }
  var enabled: Bool { get set }

  var writer: AVAssetWriter? { get set }
  var input: AVAssetWriterInput? { get set }

  var timeMultiple: Double { get set }
  var offset: CMTime { get set }
  var frameCount: Int { get set }

  var lastAppendedFrame: CMTime { get set }
  var tmpFrameBuffer: CMSampleBuffer? { get set }
  var frameChanged: Bool { get set }
  var frameRate: CMTimeScale { get }

  // MARK: Intents
  mutating func startRecording()
  mutating func stopRecording()
  mutating func resumeRecording()
  mutating func pauseRecording()
  mutating func saveRecording()

  func getFilename() -> String
}

extension Recordable {
  var frameRate: CMTimeScale {
    guard let writer = writer else { return .zero }
    return CMTimeScale(30.0)
  }

  /// Starts recording if ``enabled``
  /// This does not actually get run because Screen and Camera need different arguments
  /// However, I found it weird to have a `stopRecording`, but not a `startRecording`
  mutating func startRecording() {
    guard self.enabled else { return }
    guard self.state != .recording else { return }

    self.state = .recording
  }

  /// Stops recording if ``enabled``
  mutating func stopRecording() {
    guard self.enabled else { return }

    self.state = .stopped
    saveRecording()
  }

  mutating func resumeRecording() {
    self.state = .recording
  }

  mutating func pauseRecording() {
    self.state = .paused
  }

  mutating func saveRecording() {
    logger.log("Saving recorder")
  }

  /// Turns a `String` into a valid file path (may be a temporary folder)
  func getFileDestination(path: String) -> URL {
    var url = URL(filePath: path, directoryHint: .notDirectory, relativeTo: .temporaryDirectory)

    if let location = UserDefaults.standard.url(forKey: "saveLocation"),
      FileManager.default.fileExists(atPath: location.path),
      FileManager.default.isWritableFile(atPath: location.path)
    {
      url = URL(filePath: path, directoryHint: .notDirectory, relativeTo: location)
    } else {
      logger.error("No camera save location present")
    }

    do {  // delete old video
      try FileManager.default.removeItem(at: url)
    } catch { print("Failed to delete file \(error.localizedDescription)") }

    return url
  }

  /// Sends a notification using `UserNotifications` framework
  /// Exists on `Recordable` because this can be modified is an **iOS** application is in the future
  func sendNotification(title: String, body: String, url: URL?) {
    guard UserDefaults.standard.bool(forKey: "showNotifications") else { return }

    let center = UNUserNotificationCenter.current()

    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body

    if let url = url {
      content.userInfo = ["fileURL": url.absoluteString]
    }

    content.sound = .default  // .defaultCritical

    let request = UNNotificationRequest(
      identifier: "recordingStatusNotifications", content: content, trigger: nil)

    center.add(request) { error in
      if let error = error {
        logger.log("Failed to send notification with error \(error)")
      }
    }
  }

  /// Appends a buffer depending on a couple of factors
  /// The `tmpFrameBuffer` is used to keep track of deletable buffers
  /// Saves **30%** of space at only **2x** speed. Ostensibly much higher for higher time multiples
  func appendBuffer(buffer: CMSampleBuffer, source: InputTypes) -> (CMSampleBuffer, CMTime, Bool) {
    guard let input = input else { return (buffer, lastAppendedFrame, true) }

    // Determines if we should append
    let currentPTS = buffer.presentationTimeStamp

    let differenceTime = CMTimeMultiplyByFloat64(
      CMTime(seconds: 1.0 / 30, preferredTimescale: 30), multiplier: timeMultiple)

    var changed = frameChanged
    switch source {
    case .camera:
      changed = true  // a camera is always changed
    case .screen:
      // needs to get the attachments array
      if !changed,
        let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(
          buffer,
          createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
        let attachments = attachmentsArray.first
      {
        // okay, so we have attachments
        if let rects = attachments[.dirtyRects] as? NSArray, rects.count > 0 {
          changed = true  // if we have dirty rects, something changed
        }
      } else {
        // if we can not extract, then changed MUST be true
        changed = true
      }
    default:
      logger.warning("Unrecognized input device")
    }

    guard currentPTS > lastAppendedFrame + differenceTime || (source == .screen && !frameChanged)
    else {
      // okay to replace the tmp buffer
      return (buffer, lastAppendedFrame, changed)
    }

    guard
      let newBuffer = try? tmpFrameBuffer?.offsettingTiming(
        by: offset, multiplier: 1.0 / timeMultiple)
    else {
      return (buffer, lastAppendedFrame, true)
    }

    guard input.append(newBuffer) else {
      logger.error("failed to append data")
      return (buffer, lastAppendedFrame, true)
    }

    if let tmpFrameBuffer = tmpFrameBuffer {
      return (buffer, tmpFrameBuffer.presentationTimeStamp, source != .screen)  // we have not changed originally
    } else {
      // Initial condition
      return (buffer, buffer.presentationTimeStamp, source != .screen)
    }

  }

  /// Returns a `String` representation of the current date, used by both `Camera` and `Screen`
  ///  The intention is for this to be utilized
  var dateExtension: String {
    let currentDate = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let formattedDate = formatter.string(from: currentDate)

    return formattedDate
  }

  /// Returns a valid file extension for recording formats
  var fileExtension: String {
    var fileType: AVFileType = baseConfig.validFormats.first!
    if let fileTypeValue = UserDefaults.standard.object(forKey: "format"),
      let preferenceType = fileTypeValue as? AVFileType
    {
      fileType = preferenceType
    }

    return baseConfig.convertFormatToString(fileType)
  }

  /// Returns the length of the recording
  var time: CMTime {
    guard let tmpFrameBuffer = tmpFrameBuffer else { return CMTime.zero }

    return CMTimeMultiplyByFloat64(
      (tmpFrameBuffer.presentationTimeStamp - offset), multiplier: 1 / timeMultiple)
  }
}

extension CMSampleBuffer {
  /// Changes the speed of the sample buffer by `multiplier` in a recording with the `by` start time
  ///
  /// Does the work to create the time lapse
  func offsettingTiming(by offset: CMTime, multiplier: Float64) throws -> CMSampleBuffer {
    let newSampleTimingInfos: [CMSampleTimingInfo]

    do {
      newSampleTimingInfos = try sampleTimingInfos().map {
        var newSampleTiming = $0
        newSampleTiming.presentationTimeStamp =
          offset
          + CMTimeMultiplyByFloat64($0.presentationTimeStamp - offset, multiplier: multiplier)
        return newSampleTiming
      }
    } catch {
      newSampleTimingInfos = []
    }
    let newSampleBuffer = try CMSampleBuffer(copying: self, withNewTiming: newSampleTimingInfos)
    return newSampleBuffer
  }
}

extension URL {
  /// Returns whether or not the url is in the `URL.temporaryDirectory`
  func isInTemporaryFolder() -> Bool {
    return self.absoluteString.starts(with: URL.temporaryDirectory.absoluteString)
  }
}

/// Two-type input types
/// Used to not record non-changing frames
enum InputTypes {
  case camera
  case screen
}
