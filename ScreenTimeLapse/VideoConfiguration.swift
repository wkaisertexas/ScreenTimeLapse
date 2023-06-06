//
//  VideoConfiguration.swift
//  ScreenTimeLapse
//
//  Created by William Kaiser on 6/5/23.
//

import AVFoundation

//struct VideoConfiguration {
//    let assetPath: String
//    let outputDirectoryPath: String
//    
//    let outputContentType = AVFileType.mp4
//    let outputFileTypeProfile = AVFileTypeProfile.mpeg4AppleHLS
//    
//    let segmentDuration = 6 // I have no idea what this means
//    let segmentFilenamePrefix = "fileSequence" // maybe this is like the [v] in ffmpeg
//    let indexFileName = "prog_index.m3u8"
//    
//    let audioCompressionSettings: [String: Any] = [
//        AVFormatIDKey: kAudioFormatMPEG4AAC,
//        AVSampleRateKey: 44_100,
//        AVNumberOfChannelsKey: 2,
//        AVEncoderBitRateKey: 160_000,
//    ]
//    
//    let videoCompressionSettings: [String: Any] = [
//        AVVideoCodecKey: AVVideoCodecType.h264,
//
//        AVVideoWidthKey: 1920,
//        AVVideoHeightKey: 1080,
//
//        AVVideoCompressionPropertiesKey: [
//            kVTCompressionPropertyKey_AverageBitRate: 6_000_000,
//            kVTCompressionPropertyKey_ProfileLevel: kVTProfileLevel_H264_High_4_2,
//        ]
//    ]
//    
//    let minimumAllowablesourceFRameDuration = CMTime(value: 1, timescale: 60) // 60 fps or 1 frame every 1/60th of a second
//    
//    let audioDecompressionSettings = [
//        AVFormatIDKey: kAudioFormatLinearPCM,
//    ]
//    
//    let videoDecompressionSettings = [
//        String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_422YpCbCr8),
//    ]
//    
//}
