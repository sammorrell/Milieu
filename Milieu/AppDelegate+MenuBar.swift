#if os(macOS)
import Cocoa
import SwiftData

extension AppDelegate {
    func setupStatusBar() {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            
            if let button = statusItem?.button {
                button.title = "🖼️"
                button.action = #selector(statusBarButtonClicked(_:))
            }

            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Change Wallpaper", action: #selector(changeWallpaper), keyEquivalent: "C"))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
            statusItem?.menu = menu
        }

    @objc func statusBarButtonClicked(_ sender: Any?) {
        // If you want to do something on click (not needed if using menu)
    }

    @objc func changeWallpaper() {
        guard let container = modelContainer else { return }
        let context = ModelContext(container)
        guard let wallpapers = try? context.fetch(FetchDescriptor<Wallpaper>()),
              let wallpaper = wallpapers.randomElement() else { return }
        withSecureAccess(bookmarkData: wallpaper.bookmarkData, fallbackPath: wallpaper.filePath) { url in
            setDesktopWallpaper(to: url.path)
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

#endif
