//
//  WallpaperLibraryView.swift
//  Milieu
//
//  Created by Sam Morrell on 03/05/2025.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct WallpaperLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var wallpapers: [Wallpaper]

    @State private var selectedWallpaper: Wallpaper?
    @State private var wallpaperToDelete: Wallpaper?
    @State private var inspectedWallpaper: Wallpaper?
    @State private var isInspectorShown = false
    @State private var searchText = ""
    @State private var sortOrder: WallpaperSortOrder = .dateAdded
    @State private var showFavoritesOnly = false
    @State private var isDropTargeted = false
    @FocusState private var isGridFocused: Bool

    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 16)
    ]

    private var filtered: [Wallpaper] {
        var result = wallpapers
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        if showFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }
        switch sortOrder {
        case .dateAdded:
            result.sort { $0.dateAdded > $1.dateAdded }
        case .name:
            result.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .favorites:
            result.sort { $0.isFavorite && !$1.isFavorite }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            ZStack {
                if filtered.isEmpty {
                    emptyState
                } else {
                    grid
                }
                if isDropTargeted {
                    dropOverlay
                }
            }
            .focusable()
            .focused($isGridFocused)
            .focusEffectDisabled()
            .onKeyPress(keys: [.delete, KeyEquivalent("\u{7f}")]) { _ in
                guard let selected = selectedWallpaper else { return .ignored }
                wallpaperToDelete = selected
                return .handled
            }
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted, perform: handleDrop)
        }
        .navigationTitle("Library")
        .navigationSubtitle("\(wallpapers.count) wallpaper\(wallpapers.count == 1 ? "" : "s")")
        .onChange(of: selectedWallpaper) { _, newValue in
            if isInspectorShown, let newValue {
                inspectedWallpaper = newValue
            }
        }
        .inspector(isPresented: $isInspectorShown) {
            if let wallpaper = inspectedWallpaper {
                WallpaperInspectorView(
                    wallpaper: wallpaper,
                    onSetWallpaper: { setWallpaper(wallpaper) }
                )
                .id(wallpaper.id)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No Selection")
                        .font(.headline)
                    Text("Select a wallpaper and press ⓘ to inspect it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .alert(item: $wallpaperToDelete) { wallpaper in
            Alert(
                title: Text("Remove \"\(wallpaper.name)\"?"),
                message: Text("This will remove the wallpaper from your library. The original file will not be deleted."),
                primaryButton: .destructive(Text("Remove")) {
                    removeWallpaper(wallpaper)
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            .frame(maxWidth: 260)

            Spacer()

            Toggle(isOn: $showFavoritesOnly) {
                Image(systemName: "heart.fill")
            }
            .toggleStyle(.button)
            .tint(.red)
            .help("Show favorites only")

            Picker("Sort by", selection: $sortOrder) {
                ForEach(WallpaperSortOrder.allCases) { order in
                    Text(order.label).tag(order)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)

            Button(action: addWallpapers) {
                Label("Add", systemImage: "plus")
            }

            Toggle(isOn: $isInspectorShown) {
                Image(systemName: "sidebar.right")
            }
            .toggleStyle(.button)
            .help("Toggle Inspector")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(filtered) { wallpaper in
                    WallpaperCard(
                        wallpaper: wallpaper,
                        isSelected: selectedWallpaper?.id == wallpaper.id,
                        onSetWallpaper: { setWallpaper(wallpaper) },
                        onToggleFavorite: { toggleFavorite(wallpaper) },
                        onRemove: { wallpaperToDelete = wallpaper },
                        onInspect: { inspectedWallpaper = wallpaper; isInspectorShown = true }
                    )
                    .onTapGesture(count: 2) {
                        setWallpaper(wallpaper)
                    }
                    .onTapGesture {
                        selectedWallpaper = wallpaper
                        isGridFocused = true
                    }
                }
            }
            .padding(16)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            if searchText.isEmpty && !showFavoritesOnly {
                Text("No Wallpapers")
                    .font(.title2).bold()
                Text("Add images to your library to get started.")
                    .foregroundStyle(.secondary)
                Button("Add Wallpapers", action: addWallpapers)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
            } else {
                Text("No Results")
                    .font(.title2).bold()
                Text("Try adjusting your search or filters.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var dropOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.accentColor, lineWidth: 3)
            .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.fill)
                    Text("Drop to Add to Library")
                        .font(.headline)
                        .foregroundStyle(.fill)
                }
            }
            .padding(12)
            .allowsHitTesting(false)
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var accepted = false
        for provider in providers {
            guard provider.canLoadObject(ofClass: URL.self) else { continue }
            accepted = true
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                let values = try? url.resourceValues(forKeys: [.contentTypeKey])
                guard values?.contentType?.conforms(to: .image) == true else { return }
                let name = url.deletingPathExtension().lastPathComponent
                // Create bookmark while sandbox access is still active.
                let bookmark = makeBookmark(for: url)
                Task { @MainActor in
                    modelContext.insert(Wallpaper(name: name, filePath: url.path, bookmarkData: bookmark))
                }
            }
        }
        return accepted
    }

    private func addWallpapers() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        panel.message = "Choose wallpaper images to add to your library"

        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            let name = url.deletingPathExtension().lastPathComponent
            let bookmark = makeBookmark(for: url)
            modelContext.insert(Wallpaper(name: name, filePath: url.path, bookmarkData: bookmark))
        }
    }

    private func setWallpaper(_ wallpaper: Wallpaper) {
        withSecureAccess(bookmarkData: wallpaper.bookmarkData, fallbackPath: wallpaper.filePath) { url in
            setDesktopWallpaper(to: url.path)
        }
    }

    private func toggleFavorite(_ wallpaper: Wallpaper) {
        wallpaper.isFavorite.toggle()
    }

    private func removeWallpaper(_ wallpaper: Wallpaper) {
        if selectedWallpaper?.id == wallpaper.id {
            selectedWallpaper = nil
        }
        modelContext.delete(wallpaper)
    }
}

enum WallpaperSortOrder: String, CaseIterable, Identifiable {
    case dateAdded, name, favorites

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dateAdded: return "Date Added"
        case .name: return "Name"
        case .favorites: return "Favorites First"
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Wallpaper.self, configurations: config)
    for sample in Wallpaper.previewSamples {
        container.mainContext.insert(sample)
    }
    return WallpaperLibraryView()
        .modelContainer(container)
        .frame(width: 900, height: 600)
}
