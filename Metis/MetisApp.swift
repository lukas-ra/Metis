//
//  MetisApp.swift
//  Metis
//
//  Created by Lukas Raffelt on 02.02.26.
//

import SwiftUI
import CoreData

@main
struct MetisApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
