//
//  ScreenTimeLapseApp.swift
//  ScreenTimeLapse
//
//  Created by William Kaiser on 1/1/23.
//

/**
Notes for the project:
 
 - Learn about persistence controllers
*/

import SwiftUI

@main
struct ScreenTimeLapseApp: App {
    let persistenceController = PersistenceController.shared
     
    var body: some Scene { // TODO: Figure out what in the fuck this should be
//        MenuBarExtra{
//            ContentView()
//        } label: {
//            Text("🎥")
//        }
        
        WindowGroup("🎥"){
            ContentView()
        }
    }

}
