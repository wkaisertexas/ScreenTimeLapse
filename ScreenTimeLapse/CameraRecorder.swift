//
//  CameraRecorder.swift
//  ScreenTimeLapse
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
    
    let callback: (CMSampleBuffer) -> Void
    
    let captureQue = DispatchQueue(label: "com.myapp.captureQueue")
    
    init(device: AVCaptureDevice, callback: @escaping (CMSampleBuffer) -> Void){
        self.callback = callback

        super.init()        
        
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
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        captureQue.async {
            self.callback(sampleBuffer)
        }
    }
}
