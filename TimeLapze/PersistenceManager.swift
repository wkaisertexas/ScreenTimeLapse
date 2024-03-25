import AVFoundation
import SwiftUI

class UserDefaultsManager {
  static let shared = UserDefaultsManager()

  func getUsername() -> String? {

    UserDefaults.standard.object(forKey: "frameRate")! as! AVFileType
    return UserDefaults.standard.string(forKey: "username")
  }
}
