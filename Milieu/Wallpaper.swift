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

    init(name: String, filePath: String, bookmarkData: Data? = nil, dateAdded: Date = .now, isFavorite: Bool = false, tags: [String] = []) {
        self.id = UUID()
        self.name = name
        self.filePath = filePath
        self.bookmarkData = bookmarkData
        self.dateAdded = dateAdded
        self.isFavorite = isFavorite
        self.tags = tags
    }
    
    public func showInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: filePath)])
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
