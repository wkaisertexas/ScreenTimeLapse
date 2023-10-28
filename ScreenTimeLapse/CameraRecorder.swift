//
//  Shit.swift
//  TestPRoject
//
//  Created by William Kaiser on 10/25/23.
//

import Foundation
import AVFoundation
import CoreMedia
import SwiftUI
import os

import AppKit
import AppIntents

class RecordVideo: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession?
    var videoDataOutput: AVCaptureVideoDataOutput?
    var camera: AVCaptureDevice?
    var camptureSessionInput: AVCaptureDeviceInput?
    
    init(device: AVCaptureDevice){
        super.init()
        
        Task(priority: .userInitiated){
            
//            let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: AVMediaType.video, position: .unspecified)
//
//            // get the front camera
//            print(discovery.devices)
//            let camera = discovery.devices.first { device in
//                device.manufacturer == "Apple Inc."
//            }!


            let captureSession = AVCaptureSession()
            let cameraInput = try! AVCaptureDeviceInput(device: device)
            captureSession.addInput(cameraInput)

            // Adding the output to the camera session
            let out = AVCaptureVideoDataOutput()

            let availableFormatTypes = out.availableVideoPixelFormatTypes
            out.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(availableFormatTypes.first!),
                kCVPixelBufferIOSurfacePropertiesKey as String : [:]
            ]

            out.setSampleBufferDelegate(self, queue: .global(qos: .userInitiated))
            out.alwaysDiscardsLateVideoFrames = true

            captureSession.addOutput(out)
            captureSession.startRunning()
//
//            self.captureSession = captureSession
//            self.cameraInput = cameraInput
//            self.videoOutput = out
//
            
//            // finds the front camera
//            let discovery = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: AVMediaType.video, position: .unspecified)
//
//            // get the front camera
//            print(discovery.devices)
//            let camera = discovery.devices.first { device in
//                device.manufacturer == "Apple Inc."
//            }!
//
//            // capture session
//            let captureSession = AVCaptureSession()
//
//            let captureSessionInput = try! AVCaptureDeviceInput(device: camera)
//            captureSession.addInput(captureSessionInput)
//
//            let videoDataOutput = AVCaptureVideoDataOutput()
//            let availablePixelFormatTypes = videoDataOutput.availableVideoPixelFormatTypes
//            print("Available Pixel Format Types", availablePixelFormatTypes)
//
//            videoDataOutput.videoSettings = [
//                kCVPixelBufferPixelFormatTypeKey as String: Int(availablePixelFormatTypes.first!),
//                kCVPixelBufferIOSurfacePropertiesKey as String : [:]
//            ]
//            videoDataOutput.setSampleBufferDelegate(self, queue: .global(qos: .userInitiated))
//            videoDataOutput.alwaysDiscardsLateVideoFrames = true
//
//            captureSession.addOutput(videoDataOutput)
//
//            captureSession.startRunning()
            
            self.videoDataOutput = out
            self.captureSession = captureSession
            self.camera = device
            self.camptureSessionInput = cameraInput
        }
       
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print(sampleBuffer)
        print("Sample Buffer")

    }
    
}

func convertSampleBufferToImage(sampleBuffer: CMSampleBuffer) -> NSImage? {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
        return nil
    }

    CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)

    let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
    let width = CVPixelBufferGetWidth(imageBuffer)
    let height = CVPixelBufferGetHeight(imageBuffer)

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: baseAddress,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
    ) else {
        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        return nil
    }

    if let cgImage = context.makeImage() {
        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        return NSImage(cgImage: cgImage, size: NSZeroSize)
    }

    CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
    return nil
}

func saveImageToDisk(image: NSImage, filePath: String) -> Bool {
    if let tiffData = image.tiffRepresentation {
        do {
            try tiffData.write(to: URL(fileURLWithPath: filePath))
            return true
        } catch {
            print("Error saving image: \(error)")
            return false
        }
    }
    return false
}



