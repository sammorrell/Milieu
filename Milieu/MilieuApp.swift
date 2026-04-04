//
//  MilieuApp.swift
//  Milieu
//
//  Created by Sam Morrell on 03/05/2025.
//

import SwiftUI
import SwiftData

@main
struct MilieuApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Wallpaper.self,
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    appDelegate.modelContainer = sharedModelContainer
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

