//
//  Wallpaper.swift
//  Milieu
//
//  Created by Sam Morrell on 03/05/2025.
//

import Foundation
import SwiftData
import AppKit

@Model
final class Wallpaper: Identifiable {
    var id: UUID
    var name: String
    var filePath: String
    var bookmarkData: Data?
    var dateAdded: Date
    var isFavorite: Bool
    var tags: [String]
    var sourceUrl: URL?

    init(name: String, filePath: String, bookmarkData: Data? = nil, dateAdded: Date = .now, isFavorite: Bool = false, tags: [String] = [], sourceUrl: URL? = .none) {
        self.id = UUID()
        self.name = name
        self.filePath = filePath
        self.bookmarkData = bookmarkData
        self.dateAdded = dateAdded
        self.isFavorite = isFavorite
        self.tags = tags
        self.sourceUrl = sourceUrl
    }
    
    public func showInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: filePath)])
    }
    
    public func sourceUrlToPasteboard() {
        if let url = sourceUrl {
            #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(url.absoluteString, forType: .string)
            #elseif os(iOS)
            UIPasteboard.general.clearContents()
            UIPasteboard.general.setString(url.absoluteString, forType: .string)
            #endif
            
        }
    }
}

extension Wallpaper {
    static var previewSamples: [Wallpaper] {
        [
            ("Big Sur", "/Library/Desktop Pictures/Big Sur.heic"),
            ("Catalina", "/Library/Desktop Pictures/Catalina.heic"),
            ("macOS Sequoia", "/Library/Desktop Pictures/macOS Sequoia.heic"),
            ("macOS Sonoma", "/Library/Desktop Pictures/macOS Sonoma.heic"),
            ("macOS Monterey", "/Library/Desktop Pictures/macOS Monterey.heic"),
            ("macOS Ventura", "/Library/Desktop Pictures/macOS Ventura.heic"),
            ("Mojave Dynamic", "/Library/Desktop Pictures/Mojave.heic"),
            ("Sierra", "/Library/Desktop Pictures/Sierra.jpg"),
        ].map { (name, path) in
            Wallpaper(name: name, filePath: path)
        }
    }
}
