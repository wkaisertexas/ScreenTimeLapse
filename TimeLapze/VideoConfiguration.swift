import AVFoundation

enum VideoSettings : String {
    case h264_sRGB
    case hevc_displayP3
    
    var description : String {
        switch self {
        case .h264_sRGB : return "h.264 - sRGB"
        case .hevc_displayP3 : return "hevc - displayP3"
        }
    }
    
    var preset : AVOutputSettingsPreset {
        switch self {
        case .h264_sRGB : return .hevc3840x2160
        case .hevc_displayP3 : return .hevc7680x4320
        }
    }
    
    var videoCodec : AVVideoCodecType {
        switch self {
        case .h264_sRGB: return .h264
        case .hevc_displayP3: return .hevc
        }
    }
    
    var colorProperties: [String: Any] {
        switch self {
        case .h264_sRGB : return [
            AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
            AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
            AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
        ]
        case .hevc_displayP3 : return [
            AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
            AVVideoColorPrimariesKey: AVVideoColorPrimaries_P3_D65,
            AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
        ]
        }
    }
}

struct VideoConfiguration {
    let validFormats: [AVFileType] = [
        .mov, .mp4, .m4v
    ]
    
    let HELP = "https://github.com/wkaisertexas/ScreenTimeLapse/issues"
    let ABOUT = "https://github.com/wkaisertexas/ScreenTimeLapse"
    
    let logFrequency = 200
    
    func convertFormatToString(_ input: AVFileType) -> String {
        switch(input){
        case .mov:
            return ".mov"
        case .mp4:
            return ".mp4"
        case .m4v:
            return ".m4v"
        default:
            return "Unsupported format"
        }
    }
    
}

let baseConfig = VideoConfiguration()
