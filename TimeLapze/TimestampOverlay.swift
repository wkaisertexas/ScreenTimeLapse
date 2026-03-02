import AVFoundation
import CoreImage
import CoreGraphics
import CoreText
import Foundation
import AppKit

/// Renders a date/time string onto a video frame in the top-right corner.
/// Used when "Show date & time on video" is enabled in preferences.
enum TimestampOverlay {
  private static let padding: CGFloat = 16
  private static var ciContext: CIContext = CIContext(options: [.useSoftwareRenderer: false])

  /// Whether the overlay should be applied for the given source (used to decide writer format hint).
  static func shouldUseOverlayFormat(for source: InputTypes) -> Bool {
    switch source {
    case .camera:
      return UserDefaults.standard.bool(forKey: "cameraTimestampEnabled")
    case .screen:
      return UserDefaults.standard.bool(forKey: "screenTimestampEnabled")
    }
  }

  /// Returns a format description for 32BGRA at the given dimensions.
  /// Use as AVAssetWriterInput.sourceFormatHint when overlay is enabled so the writer accepts overlay output.
  static func formatDescription32BGRA(width: Int, height: Int) -> CMFormatDescription? {
    guard let pixelBuffer = createBGRAPixelBuffer(width: width, height: height) else { return nil }
    var formatDescription: CMFormatDescription?
    let status = CMVideoFormatDescriptionCreateForImageBuffer(
      allocator: kCFAllocatorDefault,
      imageBuffer: pixelBuffer,
      formatDescriptionOut: &formatDescription
    )
    return status == noErr ? formatDescription : nil
  }

  /// Applies the timestamp overlay to a sample buffer and returns a new sample buffer
  /// with the same timing. The output pixel format is 32BGRA so the writer must accept it.
  /// Returns nil if overlay is disabled for this source or rendering fails.
  static func apply(
    to sampleBuffer: CMSampleBuffer,
    displayTime: Date,
    source: InputTypes
  ) -> CMSampleBuffer? {
    // Get source-specific settings
    let prefix: String
    switch source {
    case .camera:
      guard UserDefaults.standard.bool(forKey: "cameraTimestampEnabled") else { return nil }
      prefix = "cameraTimestamp"
    case .screen:
      guard UserDefaults.standard.bool(forKey: "screenTimestampEnabled") else { return nil }
      prefix = "screenTimestamp"
    }

    let formatRaw = UserDefaults.standard.string(forKey: "\(prefix)Format")
      ?? TimestampOverlayFormat.mediumDateTime.rawValue
    let format = TimestampOverlayFormat(rawValue: formatRaw) ?? .mediumDateTime
    let fontName = UserDefaults.standard.string(forKey: "\(prefix)FontName") ?? "Helvetica"
    let fontSize = CGFloat(UserDefaults.standard.double(forKey: "\(prefix)FontSize"))
    let fontSizeSafe = fontSize > 0 ? fontSize.clamped(to: 10...72) : 24.0
    let colorHex = UserDefaults.standard.string(forKey: "\(prefix)ColorHex") ?? "#FFFFFF"

    let formatter = DateFormatter()
    formatter.dateFormat = format.dateFormat
    formatter.locale = Locale.current
    let text = formatter.string(from: displayTime)

    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)

    let sourceImage = CIImage(cvPixelBuffer: pixelBuffer)
    guard let outputBuffer = createBGRAPixelBuffer(width: width, height: height) else { return nil }
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }

    // Convert source to CGImage first (handles 10-bit ARGB2101010 from screen capture)
    guard let cgImage = ciContext.createCGImage(
      sourceImage,
      from: CGRect(x: 0, y: 0, width: width, height: height),
      format: .BGRA8,
      colorSpace: colorSpace
    ) else { return nil }

    CVPixelBufferLockBaseAddress(outputBuffer, [])
    defer { CVPixelBufferUnlockBaseAddress(outputBuffer, []) }

    guard let baseAddress = CVPixelBufferGetBaseAddress(outputBuffer) else { return nil }
    let bytesPerRow = CVPixelBufferGetBytesPerRow(outputBuffer)

    // BGRA: bytes in memory are B, G, R, A. With byteOrder32Little + premultipliedFirst = BGRA
    let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
    guard let context = CGContext(
      data: baseAddress,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: colorSpace,
      bitmapInfo: bitmapInfo
    ) else { return nil }

    // Draw the source image into the BGRA buffer
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    let cgColor = cgColorFromHex(colorHex, colorSpace: colorSpace) ?? CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
    let font = NSFont(name: fontName, size: fontSizeSafe) ?? NSFont.systemFont(ofSize: fontSizeSafe)
    let ctFont = CTFontCreateWithName(font.fontName as CFString, fontSizeSafe, nil)
    let attributes: [CFString: Any] = [
      kCTFontAttributeName: ctFont,
      kCTForegroundColorAttributeName: cgColor,
    ]
    let attributedString = CFAttributedStringCreate(
      kCFAllocatorDefault,
      text as CFString,
      attributes as CFDictionary
    )!
    let line = CTLineCreateWithAttributedString(attributedString)
    let textBounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)

    let x = CGFloat(width) - textBounds.width - Self.padding
    let baselineY = CGFloat(height) - textBounds.height - Self.padding
    if x >= 0, baselineY >= 0 {
      context.saveGState()
      context.setFillColor(cgColor)
      context.textPosition = CGPoint(x: x, y: baselineY)
      CTLineDraw(line, context)
      context.restoreGState()
    }
    return createSampleBuffer(from: outputBuffer, timing: sampleBuffer)
  }

  private static func createBGRAPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
    var buffer: CVPixelBuffer?
    let attrs: [CFString: Any] = [
      kCVPixelBufferCGImageCompatibilityKey: true,
      kCVPixelBufferCGBitmapContextCompatibilityKey: true,
      kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary,
    ]
    let status = CVPixelBufferCreate(
      kCFAllocatorDefault,
      width,
      height,
      kCVPixelFormatType_32BGRA,
      attrs as CFDictionary,
      &buffer
    )
    return status == kCVReturnSuccess ? buffer : nil
  }

  private static func cgColorFromHex(_ hex: String, colorSpace: CGColorSpace) -> CGColor? {
    let s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    guard s.count == 6 || s.count == 8,
      let value = UInt32(s, radix: 16)
    else { return nil }
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat
    let a: CGFloat
    if s.count == 8 {
      r = CGFloat((value >> 24) & 0xFF) / 255
      g = CGFloat((value >> 16) & 0xFF) / 255
      b = CGFloat((value >> 8) & 0xFF) / 255
      a = CGFloat(value & 0xFF) / 255
    } else {
      r = CGFloat((value >> 16) & 0xFF) / 255
      g = CGFloat((value >> 8) & 0xFF) / 255
      b = CGFloat(value & 0xFF) / 255
      a = 1.0
    }
    return CGColor(colorSpace: colorSpace, components: [r, g, b, a])
  }

  private static func createSampleBuffer(from pixelBuffer: CVPixelBuffer, timing source: CMSampleBuffer) -> CMSampleBuffer? {
    var formatDescription: CMFormatDescription?
    var status = CMVideoFormatDescriptionCreateForImageBuffer(
      allocator: kCFAllocatorDefault,
      imageBuffer: pixelBuffer,
      formatDescriptionOut: &formatDescription
    )
    guard status == noErr, let formatDesc = formatDescription else { return nil }

    var timingInfo = CMSampleTimingInfo(
      duration: .invalid,
      presentationTimeStamp: .zero,
      decodeTimeStamp: .invalid
    )
    _ = CMSampleBufferGetSampleTimingInfoArray(source, entryCount: 1, arrayToFill: &timingInfo, entriesNeededOut: nil)

    var sampleBuffer: CMSampleBuffer?
    status = CMSampleBufferCreateForImageBuffer(
      allocator: kCFAllocatorDefault,
      imageBuffer: pixelBuffer,
      dataReady: true,
      makeDataReadyCallback: nil,
      refcon: nil,
      formatDescription: formatDesc,
      sampleTiming: &timingInfo,
      sampleBufferOut: &sampleBuffer
    )
    return status == noErr ? sampleBuffer : nil
  }
}

private extension Comparable {
  func clamped(to range: ClosedRange<Self>) -> Self {
    min(max(self, range.lowerBound), range.upperBound)
  }
}
