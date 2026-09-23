import SwiftUI
import AppKit

@main
struct YabaiControlApp: App {
    @StateObject private var service = YabaiService.shared

    init() {
        // Run as accessory item in menu bar
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        // macOS Menu Bar Extra (MenuBar Popover)
        MenuBarExtra("YabaiControl", systemImage: "squareshape.split.2x2") {
            MenuBarView()
                .environmentObject(service)
        }
        .menuBarExtraStyle(.window)

        // Configuration / Settings Window
        Window("Yabai & skhd Configuration", id: "settings") {
            SettingsView()
                .environmentObject(service)
        }
        .windowResizability(.contentSize)
    }
}
