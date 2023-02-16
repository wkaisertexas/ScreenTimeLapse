//
//  Recorder.swift
//  ScreenTimeLapse
//
//  Created by William Kaiser on 2/16/23.
//

import Foundation
import AVFoundation

struct Recorder{
//    let writer: AVAssetWriter
//    let file: URL
    
    let fileOut: AVCaptureFileOutput
    let captureSession: AVCaptureSession
}

class StreamDelegate : NSObject, SCStreamDelegate{
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("The stream stopped")
    }
}
