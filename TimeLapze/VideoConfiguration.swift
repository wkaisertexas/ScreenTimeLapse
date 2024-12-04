import AVFoundation

/// Settings for color-accurate recording
/// from: https://nonstrict.eu/blog/2023/recording-to-disk-with-screencapturekit/
enum VideoSettings: String {
  case h264sRGB
  case hevcDisplayP3

  var description: String {
    switch self {
    case .h264sRGB: return "h.264 - sRGB"
    case .hevcDisplayP3: return "hevc - displayP3"
    }
  }

  var preset: AVOutputSettingsPreset {
    switch self {
    case .h264sRGB: return .hevc3840x2160
    case .hevcDisplayP3: return .hevc7680x4320
    }
  }

  var videoCodec: AVVideoCodecType {
    switch self {
    case .h264sRGB: return .h264
    case .hevcDisplayP3: return .hevc
    }
  }

  var colorProperties: [String: Any] {
    switch self {
    case .h264sRGB:
      return [
        AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
        AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
        AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
      ]
    case .hevcDisplayP3:
      return [
        AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
        AVVideoColorPrimariesKey: AVVideoColorPrimaries_P3_D65,
        AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
      ]
    }
  }
}

/// General configuration struct for the user interface
///
/// Putting this in VideoConfiguration is a little strange and this code should probably be refactored
struct VideoConfiguration {
  let validFormats: [AVFileType] = [
    .mov, .mp4,
  ]

  let help = URL(string: "https://github.com/wkaisertexas/ScreenTimeLapse/issues")!
  let about = URL(string: "https://github.com/wkaisertexas/ScreenTimeLapse")!

  /// Constant quality threshold for recording video
  let quality = 0.85

  let logFrequency = 200

  func convertFormatToString(_ input: AVFileType) -> String {
    switch input {
    case .mov:
      return ".mov"
    case .mp4:
      return ".mp4"
    default:
      return "Unsupported format"
    }
  }

}

let baseConfig = VideoConfiguration()
