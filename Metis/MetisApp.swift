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
            // Use NSViewControllerRepresentable to wrap the Metal view controller
            MetalViewControllerRepresentable()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
// Wrapper to use NSViewController in SwiftUI
struct MetalViewControllerRepresentable: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> ViewController {
        return ViewController()
    }

    func updateNSViewController(_ nsViewController: ViewController, context: Context) {
    }

    typealias NSViewControllerType = ViewController
}
