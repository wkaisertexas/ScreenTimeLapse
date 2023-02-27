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
    let recorderViewModel = RecorderViewModel()
     
    var body: some Scene {
        MenuBarExtra{
            ContentView().environmentObject(recorderViewModel)
        } label: {
            Text(verbatim: recorderViewModel.state.description)
        }
    }
}
