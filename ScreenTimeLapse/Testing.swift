//
//  Testing.swift
//  ScreenTimeLapse
//
//  Created by William Kaiser on 6/5/23.
//

import Foundation
import CoreMedia
import CoreImage
import SwiftUI
import AVFoundation

// Because things are not working, a testing class is just used to handle all of the code to run sanity checks

import Foundation
import CoreMedia

func logVideoProperties(of sampleBuffer: CMSampleBuffer) {
    guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
        logger.log("Invalid sample buffer format description")
        return
    }
    
    let mediaType = CMFormatDescriptionGetMediaType(formatDescription)
    if mediaType != kCMMediaType_Video {
        logger.log("Sample buffer is not of video media type")
        return
    }

    // get information about the sample buffer
    logger.log("\(CMSampleBufferGetNumSamples(sampleBuffer))")
    logger.log("\(CMSampleBufferGetDuration(sampleBuffer).seconds)")
    logger.log("\(CMSampleBufferGetOutputDuration(sampleBuffer).seconds)")
    logger.log("\(CMSampleBufferGetDecodeTimeStamp(sampleBuffer).seconds)")
        
//    var itemIndex: CMItemIndex = CMTime.zero
//    let pointer = UnsafeMutablePointer<CMItemIndex>.allocate(capacity: 1)
//    pointer.initialize(to: itemIndex)

    
//    let timeRange = CMTimeRangeMake(start: CMTime.zero, duration: CMTimeMake(value: 10, timescale: 1))
//    let pointer = UnsafeMutablePointer<CMTimeRange>.allocate(capacity: 1)
//    pointer.initialize(to: timeRange)
//    
//    let sampleInfo = CMSampleBufferGetSampleTimingInfo(sampleBuffer, at: CMTime.zero, timingInfoOut: pointer);
//    
//    print("\(pointer.pointee.duration)")
//    
//    pointer.deallocate();
//    
//    let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
//    logger.log("Video Dimensions: \(dimensions.width) x \(dimensions.height)")
//    
//        logger.log("Presentation Timestamp: \(sampleBuffer.presentationTimeStamp)")
//        logger.log("Decode Timestamp: \(sampleBuffer.decodeTimeStamp)")
//        logger.log("Duration: \(sampleBuffer.duration)")
//        
//    // Additional properties can be extracted and logged if needed
//
//    // Example: Frame rate
//    if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false),
//        let attachment = CFArrayGetValueAtIndex(attachments, 0) as? CFDictionary,
//        let frameRate = CFDictionaryGetValue(attachment, Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque()) {
//        logger.log("Frame Rate: \(frameRate)")
//    }
//
//    // Example: Pixel format
//    let pixelFormat = CMFormatDescriptionGetMediaSubType(formatDescription)
//    logger.log("Pixel Format: \(pixelFormat)")
    
    // Add more properties as needed
    
    // Note: Make sure to import the relevant frameworks and define the Logger class or use an appropriate logging mechanism
}


// note: there could be a mismatch between the cmsampletimes which is causing issues. this is definitely something to look into

// turning cmsamplebuffers into images

//func saveSampleBufferImageToDesktop(sampleBuffer: CMSampleBuffer) {
//    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else{
//        logger.error("Unable to get an image from the sample buffer")
//        return
//    }
//
//    guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else {
//        logger.error("Failed to get the base address")
//        return
//    }
//
//    CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
//
//    let width = CVPixelBufferGetWidth(imageBuffer)
//    let height = CVPixelBufferGetHeight(imageBuffer)
//    let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
//    let colorSpace = CGColorSpaceCreateDeviceRGB()
//    let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
//
//    let context = CGContext(
//        data: baseAddress,
//        width: width,
//        height: height,
//        bitsPerComponent: 8,
//        bytesPerRow: bytesPerRow,
//        space: colorSpace,
//        bitmapInfo: bitmapInfo
//    )
//
//    guard let cgImage = context?.makeImage() else {
//        logger.error("Failed to create CGImage from Context")
//        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
//        return
//    }
//
//    let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
//    let imageURL = desktopURL.appendingPathComponent("sampleBufferImage.jpg")
//
//    guard let destination = CGImageDestinationCreateWithURL(imageURL as CFURL, kUTTypeJPEG, 1, nil) else {
//        logger.error("unable to set destination")
//        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
//        return
//    }
//
//    CGImageDestinationAddImage(destination, cgImage, nil)
//
//    if CGImageDestinationFinalize(destination){
//        logger.debug("Working as indended")
//    } else {
//        logger.error("Unable to save image")
//    }
//
//
//    CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
//}
//
//
///// Converting sample buffers to image alerts shown
//func getUIImageFromBuffer(buffer: CMSampleBuffer) -> NSImage?{
//    if let cvImageBuffer = CMSampleBufferGetImageBuffer(buffer){
//        let ciimage = CIImage(cvImageBuffer: cvImageBuffer)
//        let context = CIContext()
//
//        if let cgImage = context.createCGImage(ciimage, from: ciimage.extent){
//            return NSImage(cgImage: cgImage, size: NSZeroSize)
//        }
//    }
//
//    return nil
//}
//
//
//func showImageInPopup(image: NSImage) {
//    // Create an NSAlert instance
//    let alert = NSAlert()
//    alert.messageText = "Image Popup"
//
//    // Create an NSTextView to hold the image
//    let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
//    textView.textContainer?.widthTracksTextView = true
//    textView.isEditable = false
//    textView.textContainerInset = NSZeroSize
//    textView.textContainer?.lineFragmentPadding = 0
//
//    // Set the attributed string of the NSTextView with the image
//    let imageAttachment = NSTextAttachment()
//    imageAttachment.image = image
//    let imageString = NSAttributedString(attachment: imageAttachment)
//    textView.textStorage?.setAttributedString(imageString)
//
//    // Add the NSTextView to the NSAlert's accessory view
//    alert.accessoryView = textView
//
//    // Add an OK button to the NSAlert
//    alert.addButton(withTitle: "OK")
//
//    // Present the NSAlert as a modal window
//    alert.runModal()
//}
//
//func debugPrintStatus(_ status: AVAssetWriter.Status) {
//    switch status {
//        case .cancelled:
//            logger.log("Writer is canceld")
//        case .completed:
//            logger.log("Writer is completed")
//        case .writing:
//            logger.log("Writer is writing")
//        case .unknown:
//            logger.log("Writer is unknown")
//        case .failed:
//            logger.log("writer has failed")
//        default:
//            logger.log("Who knows")
//    }
//
//}
