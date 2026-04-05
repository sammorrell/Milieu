//
//  WallpaperCard.swift
//  Milieu
//
//  Created by Sam Morrell on 03/05/2025.
//

import SwiftUI

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    var isSelected: Bool = false
    var onSetWallpaper: (() -> Void)? = nil
    var onToggleFavorite: (() -> Void)? = nil
    var onRemove: (() -> Void)? = nil
    var onInspect: (() -> Void)? = nil
    var onSetWallpaperOnScreen: ((NSScreen) -> Void)? = nil

    @State private var thumbnail: NSImage?
    @State private var isRenaming = false
    @State private var editingName = ""
    @FocusState private var renameFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            thumbnailView
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                }
                .overlay(alignment: .topTrailing) {
                    Button(action: { onToggleFavorite?() }) {
                        Image(systemName: wallpaper.isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(wallpaper.isFavorite ? .red : .white)
                            .padding(5)
                            .background(.black.opacity(0.45), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(6)
                }
                .overlay(alignment: .bottomLeading) {
                    Button(action: { onInspect?() }) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(.black.opacity(0.45), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(6)
                    .help("Get Info")
                }

            nameView
                .frame(height: 16)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button("Set as Wallpaper") { onSetWallpaper?() }
            if NSScreen.screens.count > 1 {
                ForEach(NSScreen.screens, id: \.localizedName) { screen in
                    Button("Set on \(screen.localizedName)") {
                        onSetWallpaperOnScreen?(screen)
                    }
                }
            }

            Divider()
            Button("Get Info") { onInspect?() }
            Button("Rename") { startRename() }
            Button(wallpaper.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                onToggleFavorite?()
            }
            Divider()
            Button("Copy Source URL") { wallpaper.sourceUrlToPasteboard() }
                .disabled(wallpaper.sourceUrl == nil)
            Button("Show in Finder") { wallpaper.showInFinder() }
            Button("Remove from Library", role: .destructive) { onRemove?() }
        }
        .task {
            // Capture value types on the main actor before hopping threads.
            let bookmarkData = wallpaper.bookmarkData
            let filePath = wallpaper.filePath
            thumbnail = await loadThumbnail(bookmarkData: bookmarkData, fallbackPath: filePath)
        }
    }

    @ViewBuilder
    private var nameView: some View {
        if isRenaming {
            TextField("Name", text: $editingName)
                .font(.caption)
                .textFieldStyle(.plain)
                .padding(.horizontal, 4)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                .focused($renameFieldFocused)
                .onSubmit { commitRename() }
                .onKeyPress(.escape) {
                    cancelRename()
                    return .handled
                }
                .onChange(of: renameFieldFocused) { _, focused in
                    if !focused { commitRename() }
                }
        } else {
            Text(wallpaper.name)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
                .onTapGesture { startRename() }
        }
    }

    private func startRename() {
        editingName = wallpaper.name
        isRenaming = true
        renameFieldFocused = true
    }

    private func commitRename() {
        guard isRenaming else { return }
        isRenaming = false
        let trimmed = editingName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            wallpaper.name = trimmed
        }
    }

    private func cancelRename() {
        isRenaming = false
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let image = thumbnail {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(16 / 9, contentMode: .fill)
        } else {
            Rectangle()
                .fill(.secondary.opacity(0.15))
                .aspectRatio(16 / 9, contentMode: .fit)
                .overlay {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
        }
    }
}

