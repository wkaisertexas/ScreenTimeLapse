//
//  VideoConfiguration.swift
//  ScreenTimeLapse
//
//  Created by William Kaiser on 6/5/23.
//

import AVFoundation

struct VideoConfiguration {
    let validFormats: [AVFileType] = [
        .mov, .mp4, .avci, .heif
    ]
    
    let HELP = "https://github.com/wkaisertexas/ScreenTimeLapse/issues"
    let ABOUT = "https://github.com/wkaisertexas/ScreenTimeLapse"
    
    func convertFormatToString(_ input: AVFileType) -> String {
        switch(input){
            case .mov:
                return ".mov"
            case .mp4:
                return ".mp4"
            case .avci:
                return ".avci"
            case .heif:
                return ".heif"
            default:
                return "Unsupported format"
        }
    }
}

let baseConfig = VideoConfiguration()
