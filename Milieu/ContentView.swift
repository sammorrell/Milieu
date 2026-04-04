//
//  ContentView.swift
//  Milieu
//
//  Created by Sam Morrell on 03/05/2025.
//

import SwiftUI
import SwiftData

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case library = "Library"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "slider.horizontal.2.square"
        case .library: return "books.vertical.fill"
        }
    }
}

struct ContentView: View {
    @State private var selection: SidebarItem? = .library

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
            .listStyle(.sidebar)
        } detail: {
            switch selection {
            case .library, .none:
                WallpaperLibraryView()
            case .dashboard:
                DashboardPlaceholderView()
            }
        }
    }
}

struct DashboardPlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "slider.horizontal.2.square")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("Dashboard")
                .font(.title2).bold()
            Text("Coming soon.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Dashboard")
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Wallpaper.self, configurations: config)
    for sample in Wallpaper.previewSamples {
        container.mainContext.insert(sample)
    }
    return ContentView()
        .modelContainer(container)
        .frame(width: 1000, height: 650)
}
