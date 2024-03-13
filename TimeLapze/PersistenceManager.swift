//
//  PersistenceManager.swift
//  ScreenTimeLapse
//
//  Created by William Kaiser on 11/1/23.
//

import AVFoundation
import SwiftUI

class UserDefaultsManager {
  static let shared = UserDefaultsManager()

  func getUsername() -> String? {

    UserDefaults.standard.object(forKey: "frameRate")! as! AVFileType
    return UserDefaults.standard.string(forKey: "username")
  }
}
