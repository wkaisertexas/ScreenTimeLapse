//
//  VideoConfiguration.swift
//  ScreenTimeLapse
//
//  Created by William Kaiser on 6/5/23.
//

import AVFoundation

struct VideoConfiguration {
    let videoSettings: [String: Any] = [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: 1920,
        AVVideoHeightKey: 1080,
//        AVVideoCompressionPropertiesKey: [
//                AVVideoAverageBitRateKey: 6000000, // Adjust the bit rate as needed
//                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
//        ],
    ]
}

let baseConfig = VideoConfiguration()
