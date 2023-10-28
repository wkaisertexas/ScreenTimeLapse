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
    
    let callback: (CMSampleBuffer) -> Void
    
    init(device: AVCaptureDevice, callback: @escaping (CMSampleBuffer) -> Void){
        self.callback = callback

        super.init()        
        
        Task(priority: .userInitiated){
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
            
            self.videoDataOutput = out
            self.captureSession = captureSession
            self.camera = device
            self.camptureSessionInput = cameraInput
        }
       
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.callback(sampleBuffer)

    }
    
}
