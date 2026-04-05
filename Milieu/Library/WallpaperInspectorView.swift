//
//  WallpaperInspectorView.swift
//  Milieu
//

import SwiftUI
import SwiftData

struct WallpaperInspectorView: View {
    @Bindable var wallpaper: Wallpaper
    var onSetWallpaper: (() -> Void)? = nil

    @State private var thumbnail: NSImage?
    @State private var newTag = ""
    @FocusState private var tagFieldFocused: Bool

    var body: some View {
        Form {
            // Thumbnail
            Section {
                thumbnailView
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
            }

            // Name
            Section("Name") {
                TextField("Name", text: $wallpaper.name)
            }

            // Properties
            Section("Properties") {
                Toggle("Favourite", isOn: $wallpaper.isFavorite)
            }

            // Tags
            Section("Tags") {
                if wallpaper.tags.isEmpty {
                    Text("No tags")
                        .foregroundStyle(.secondary)
                }
                ForEach(wallpaper.tags, id: \.self) { tag in
                    HStack {
                        Text(tag)
                        Spacer()
                        Button {
                            wallpaper.tags.removeAll { $0 == tag }
                        } label: {
                            Image(systemName: "xmark")
                                .imageScale(.small)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack {
                    TextField("Add tag…", text: $newTag)
                        .focused($tagFieldFocused)
                        .onSubmit { addTag() }
                    if !newTag.isEmpty {
                        Button("Add", action: addTag)
                            .buttonStyle(.borderless)
                    }
                }
            }

            // Source URL
            Section("Source URL") {
                TextField(
                    "https://",
                    text: Binding(
                        get: { wallpaper.sourceUrl?.absoluteString ?? "" },
                        set: { wallpaper.sourceUrl = $0.isEmpty ? nil : URL(string: $0) }
                    )
                )
                .textContentType(.URL)
            }

            // Metadata
            Section("Info") {
                LabeledContent("Added") {
                    Text(wallpaper.dateAdded.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(.secondary)
                }
                LabeledContent("File") {
                    Text(URL(fileURLWithPath: wallpaper.filePath).lastPathComponent)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            // Actions
            Section {
                Button {
                    onSetWallpaper?()
                } label: {
                    Label("Set as Wallpaper", systemImage: "desktopcomputer")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 4, trailing: 12))

                Button {
                    wallpaper.showInFinder()
                } label: {
                    Label("Show in Finder", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 8, trailing: 12))
            }
        }
        .formStyle(.grouped)
        .navigationTitle(wallpaper.name)
        .task(id: wallpaper.id) {
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
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(.quaternary)
                .overlay { ProgressView() }
        }
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !wallpaper.tags.contains(trimmed) else {
            newTag = ""
            return
        }
        wallpaper.tags.append(trimmed)
        newTag = ""
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Wallpaper.self, configurations: config)
    let sample = Wallpaper.previewSamples[0]
    container.mainContext.insert(sample)
    return WallpaperInspectorView(wallpaper: sample)
        .modelContainer(container)
        .frame(width: 280, height: 700)
}
