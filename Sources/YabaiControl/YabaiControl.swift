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
        MenuBarExtra {
            MenuBarView()
                .environmentObject(service)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: service.menuBarIcon)
                if !service.menuBarStatusText.isEmpty {
                    Text(service.menuBarStatusText)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
            }
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
