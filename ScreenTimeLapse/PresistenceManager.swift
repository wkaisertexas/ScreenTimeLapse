//
//  PresistenceManager.swift
//  ScreenTimeLapse
//
//  Created by William Kaiser on 11/1/23.
//


import SwiftUI
import AVFoundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    func getUsername() -> String? {
        
        UserDefaults.standard.object(forKey: "frameRate")! as! AVFileType
        return UserDefaults.standard.string(forKey: "username")
    }
}
