//
//  ScreenTimeLapseApp.swift
//  ScreenTimeLapse
//
//  Created by William Kaiser on 1/1/23.
//

import SwiftUI

@main
struct ScreenTimeLapseApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
