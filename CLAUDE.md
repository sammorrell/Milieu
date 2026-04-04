# Milieu — Claude Context

Milieu is a macOS wallpaper manager written in Swift and SwiftUI, using SwiftData for persistence.

---

## Project structure

```
Milieu/
├── MilieuApp.swift                 # App entry point, ModelContainer setup
├── AppDelegate.swift               # NSApplicationDelegate, holds modelContainer ref
├── AppDelegate+MenuBar.swift       # Menu bar status item + "Change Wallpaper" action
├── ContentView.swift               # Root NavigationSplitView + SidebarItem enum
├── Wallpaper.swift                 # SwiftData model + showInFinder()
├── Item.swift                      # Unused Xcode template leftover — can be deleted
├── Library/
│   ├── WallpaperLibraryView.swift  # Main library grid view
│   └── WallpaperCard.swift         # Individual wallpaper card
└── macOS/
    └── WallpaperUtility.swift      # makeBookmark(), withSecureAccess(), setDesktopWallpaper()
```

---

## Data model — `Wallpaper`

SwiftData `@Model` class. Schema is registered in `MilieuApp.sharedModelContainer`.

| Property | Type | Notes |
|---|---|---|
| `id` | `UUID` | Manual (not SwiftData auto) |
| `name` | `String` | Display name, user-editable |
| `filePath` | `String` | POSIX path — fallback only, not used for access in sandbox |
| `bookmarkData` | `Data?` | Security-scoped bookmark — primary means of file access |
| `dateAdded` | `Date` | Defaults to `.now` |
| `isFavorite` | `Bool` | |
| `tags` | `[String]` | Stored, not yet surfaced in UI |

`Wallpaper` conforms to `Identifiable` explicitly (needed for `alert(item:)`).

`Item.swift` is an unused Xcode template stub — it is no longer in the schema and can be deleted.

---

## Sandbox & file access

The app is sandboxed (`com.apple.security.app-sandbox`). Entitlements:

- `com.apple.security.files.user-selected.read-only` — grants access to user-picked files
- `com.apple.security.files.bookmarks.app-scope` — allows creating/resolving persistent security-scoped bookmarks

**Critical pattern — always use `withSecureAccess` to read files:**

```swift
withSecureAccess(bookmarkData: wallpaper.bookmarkData, fallbackPath: wallpaper.filePath) { url in
    // use url here — security scope is open for the duration of this closure
}
```

**Always create a bookmark immediately when a file URL is obtained** (in drop handlers and NSOpenPanel callbacks), before the sandbox access window closes:

```swift
let bookmark = makeBookmark(for: url)
modelContext.insert(Wallpaper(name: name, filePath: url.path, bookmarkData: bookmark))
```

Wallpapers added before bookmarks were implemented (early in the project) will fail to load after restart — they need to be re-added.

---

## Key utilities — `WallpaperUtility.swift`

All functions are `#if os(macOS)` guarded.

- **`makeBookmark(for url: URL) -> Data?`** — creates a security-scoped bookmark
- **`withSecureAccess(bookmarkData:fallbackPath:perform:)`** — resolves bookmark, opens scope, runs closure, closes scope. `@discardableResult`.
- **`setDesktopWallpaper(to imagePath: String)`** — iterates `NSScreen.screens` and calls `NSWorkspace.shared.setDesktopImageURL` on each. Sets wallpaper on all connected displays.
- **`printCurrentWallpapers()`** — debug helper, logs current wallpaper paths for all screens.

---

## Navigation — `ContentView`

`NavigationSplitView` driven by `SidebarItem` enum (`.dashboard`, `.library`). Defaults to `.library`.

- **Library** → `WallpaperLibraryView`
- **Dashboard** → `DashboardPlaceholderView` (stub, not yet implemented)

---

## Library view — `WallpaperLibraryView`

- Adaptive `LazyVGrid` — cards 200–280pt wide
- **Add wallpapers**: toolbar "+" button → `NSOpenPanel` (multi-select, image types only)
- **Drop to add**: `.onDrop(of: [.fileURL])` on the grid/empty-state `ZStack`; non-image files are silently rejected by checking `contentType.conforms(to: .image)`
- **Search**: filters by name (case-insensitive)
- **Sort**: Date Added (desc), Name (asc), Favorites First
- **Favorites filter**: toggle button in toolbar
- **Selection**: single tap selects + focuses grid for keyboard handling
- **Set wallpaper**: double-tap card, or "Set as Wallpaper" in context menu
- **Delete**: Delete/forward-delete key on selected card, or "Remove from Library" in context menu — both show a confirmation `Alert` before deletion. Only removes from library; original file is untouched.
- **Rename**: click name label below card, or "Rename" in context menu — swaps label for inline `TextField`; Return or focus-loss commits, Escape cancels

---

## Wallpaper card — `WallpaperCard`

Callbacks (all optional): `onSetWallpaper`, `onToggleFavorite`, `onRemove`.

Thumbnail loading is async (`Task.detached`, `.utility` priority) via `withSecureAccess`. Value types (`bookmarkData`, `filePath`) are captured from the `@Model` object on the main actor before the detached task runs, to avoid cross-actor SwiftData access.

Thumbnail is downscaled to 560×315 pt (16:9) using `NSImage.draw` + `lockFocus`.

The name area is pinned to `frame(height: 16)` to prevent grid row reflow when the rename `TextField` appears.

Context menu items (in order):
1. Set as Wallpaper
2. *(divider)*
3. Rename
4. Add to Favorites / Remove from Favorites
5. *(divider)*
6. Show in Finder
7. Remove from Library *(destructive)*

---

## Menu bar

`AppDelegate` holds a `modelContainer: ModelContainer?` reference set via `.onAppear` in `MilieuApp`. "Change Wallpaper" picks a random `Wallpaper` from the store using a fresh `ModelContext` and calls `withSecureAccess` + `setDesktopWallpaper`.

---

## Known stubs / future work

- **Dashboard** — `DashboardPlaceholderView` is a placeholder; no functionality yet
- **Collections** — `SidebarItem` enum has no collections case yet; `Item.swift` was the original Xcode template stub and can be removed
- **Tags** — `tags: [String]` is stored on the model but not exposed in the UI
- **Wallpaper rotation / scheduling** — not yet implemented
- **Per-screen wallpaper setting** — currently sets all screens to the same image; no per-display control
- **Stale bookmark refresh** — `withSecureAccess` checks `isStale` but does not yet re-create and persist a fresh bookmark when staleness is detected
