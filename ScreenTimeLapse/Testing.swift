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

// note: there could be a mismatch between the cmsampletimes which is causing issues. this is definitely something to look into

// turning cmsamplebuffers into images

func saveSampleBufferImageToDesktop(sampleBuffer: CMSampleBuffer) {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else{
        logger.error("Unable to get an image from the sample buffer")
        return
    }
    
    guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else {
        logger.error("Failed to get the base address")
        return
    }
    
    CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
    
    let width = CVPixelBufferGetWidth(imageBuffer)
    let height = CVPixelBufferGetHeight(imageBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
    
    let context = CGContext(
        data: baseAddress,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    )
    
    guard let cgImage = context?.makeImage() else {
        logger.error("Failed to create CGImage from Context")
        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        return
    }
    
    let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
    let imageURL = desktopURL.appendingPathComponent("sampleBufferImage.jpg")
    
    guard let destination = CGImageDestinationCreateWithURL(imageURL as CFURL, kUTTypeJPEG, 1, nil) else {
        logger.error("unable to set destination")
        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        return
    }
    
    CGImageDestinationAddImage(destination, cgImage, nil)
    
    if CGImageDestinationFinalize(destination){
        logger.debug("Working as indended")
    } else {
        logger.error("Unable to save image")
    }
    
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
}


/// Converting sample buffers to image alerts shown
func getUIImageFromBuffer(buffer: CMSampleBuffer) -> NSImage?{
    if let cvImageBuffer = CMSampleBufferGetImageBuffer(buffer){
        let ciimage = CIImage(cvImageBuffer: cvImageBuffer)
        let context = CIContext()
        
        if let cgImage = context.createCGImage(ciimage, from: ciimage.extent){
            return NSImage(cgImage: cgImage, size: NSZeroSize)
        }
    }
    
    return nil
}


func showImageInPopup(image: NSImage) {
    // Create an NSAlert instance
    let alert = NSAlert()
    alert.messageText = "Image Popup"
    
    // Create an NSTextView to hold the image
    let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
    textView.textContainer?.widthTracksTextView = true
    textView.isEditable = false
    textView.textContainerInset = NSZeroSize
    textView.textContainer?.lineFragmentPadding = 0
    
    // Set the attributed string of the NSTextView with the image
    let imageAttachment = NSTextAttachment()
    imageAttachment.image = image
    let imageString = NSAttributedString(attachment: imageAttachment)
    textView.textStorage?.setAttributedString(imageString)
    
    // Add the NSTextView to the NSAlert's accessory view
    alert.accessoryView = textView
    
    // Add an OK button to the NSAlert
    alert.addButton(withTitle: "OK")
    
    // Present the NSAlert as a modal window
    alert.runModal()
}

func debugPrintStatus(_ status: AVAssetWriter.Status) {
    switch status {
        case .cancelled:
            logger.log("Writer is canceld")
        case .completed:
            logger.log("Writer is completed")
        case .writing:
            logger.log("Writer is writing")
        case .unknown:
            logger.log("Writer is unknown")
        case .failed:
            logger.log("writer has failed")
        default:
            logger.log("Who knows")
    }
    
}
