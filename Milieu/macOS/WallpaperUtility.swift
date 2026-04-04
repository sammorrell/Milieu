#if os(macOS)
import AppKit

/// Creates a security-scoped bookmark for a user-selected URL so access
/// persists across app restarts in the sandbox.
func makeBookmark(for url: URL) -> Data? {
    try? url.bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
    )
}

/// Resolves `bookmarkData` to a security-scoped URL, calls `action` with it,
/// then releases the security scope. Falls back to a plain file URL from
/// `fallbackPath` if the bookmark is absent or cannot be resolved.
@discardableResult
func withSecureAccess<T>(bookmarkData: Data?, fallbackPath: String, perform action: (URL) -> T?) -> T? {
    if let data = bookmarkData {
        var isStale = false
        if let url = try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) {
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }
            return action(url)
        }
    }
    return action(URL(fileURLWithPath: fallbackPath))
}

func setDesktopWallpaper(to imagePath: String) {
    let url = URL(fileURLWithPath: imagePath)
    for screen in NSScreen.screens {
        do {
            try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
        } catch {
            print("Failed to set wallpaper on \(screen.localizedName): \(error)")
        }
    }
}

func printCurrentWallpapers() {
    for screen in NSScreen.screens {
        if let wallpaperURL = NSWorkspace.shared.desktopImageURL(for: screen) {
            print("Wallpaper for screen \(screen.localizedName): \(wallpaperURL.path)")
        } else {
            print("No wallpaper set for screen \(screen.localizedName)")
        }
    }
}
#endif
