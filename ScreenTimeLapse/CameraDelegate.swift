//
//  CameraDelegate.swift
//  ScreenTimeLapse
//
//  Created by William Kaiser on 10/26/23.
//

import AVFoundation

class CameraDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    override init(){
        super.init()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print(sampleBuffer)
    }
}
