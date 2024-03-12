import Foundation
import AVFoundation
import CoreMedia
import SwiftUI
import os
import AppKit
import AppIntents

/// Takes in a `AVCaptureDevice` and a callback which takes a `CMSampleBuffer`
/// Feeds all camera outputs to the callback
class RecordVideo: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession?
    var videoDataOutput: AVCaptureVideoDataOutput?
    var camera: AVCaptureDevice?
    var camptureSessionInput: AVCaptureDeviceInput?
    
    let callback: (CMSampleBuffer) -> Void
    
    let captureQue = DispatchQueue(label: "com.smartservices.TimeLapze")
    
    init(device: AVCaptureDevice, callback: @escaping (CMSampleBuffer) -> Void){
        // Initializes the AVCaptureVideoDataOutputSampleBuffer Delegate
        self.callback = callback
        super.init()
        
        // Creates the capture session
        let captureSession = AVCaptureSession()
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        captureSession.addInput(cameraInput)

        // Configuring and adding a destination for the data in the captureSession
        let out = AVCaptureVideoDataOutput()
        let availableFormatTypes = out.availableVideoPixelFormatTypes
        out.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(availableFormatTypes.first!),
            kCVPixelBufferIOSurfacePropertiesKey as String : [:]
        ]
        out.setSampleBufferDelegate(self, queue: .global(qos: .userInitiated))
        out.alwaysDiscardsLateVideoFrames = true

        captureSession.addOutput(out)
            
        // Saving things to class variables
        self.videoDataOutput = out
        self.captureSession = captureSession
        self.camera = device
        self.camptureSessionInput = cameraInput
    }
    
    func startRunning(){
        self.captureSession!.startRunning()
    }
    
    func stopSession(){
        self.captureSession!.stopRunning()
    }
    
    func isRecording() -> Bool{
        return self.captureSession?.isRunning ?? false
    }
    
    /// Captures `CMSampleBuffers` with `captureQue` to ensure serialization of added information
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        captureQue.async {
            self.callback(sampleBuffer)
        }
    }
}
