import Foundation


enum RecordingState : CustomStringConvertible{
    var description: String {
        switch self{
            case.stopped:
                return "🎥"
            case.paused:
                return "▶️"
            case.recording:
                return "⏸️"
        }
    }
    
    case stopped
    case recording
    case paused
}
