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

    @State private var thumbnail: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                thumbnailView
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                    }

                Button(action: { onToggleFavorite?() }) {
                    Image(systemName: wallpaper.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(wallpaper.isFavorite ? .red : .white)
                        .padding(5)
                        .background(.black.opacity(0.45), in: Circle())
                }
                .buttonStyle(.plain)
                .padding(6)
            }

            Text(wallpaper.name)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button("Set as Wallpaper") { onSetWallpaper?() }
            Divider()
            Button(wallpaper.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                onToggleFavorite?()
            }
            Divider()
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

private func loadThumbnail(bookmarkData: Data?, fallbackPath: String) async -> NSImage? {
    await Task.detached(priority: .utility) {
        withSecureAccess(bookmarkData: bookmarkData, fallbackPath: fallbackPath) { url in
            guard let image = NSImage(contentsOf: url) else { return nil }
            let targetSize = NSSize(width: 560, height: 315)
            let thumb = NSImage(size: targetSize)
            thumb.lockFocus()
            image.draw(in: NSRect(origin: .zero, size: targetSize),
                       from: .zero,
                       operation: .copy,
                       fraction: 1.0)
            thumb.unlockFocus()
            return thumb
        }
    }.value
}
