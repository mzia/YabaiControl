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
            HStack(spacing: 3) {
                Image(systemName: service.menuBarIcon)

                if service.isUpdatePendingRestart {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 8, weight: .heavy))
                }

                if !service.menuBarStatusText.isEmpty {
                    Text(service.menuBarStatusText)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
            }
            .help(service.isUpdatePendingRestart ? "Update ready — restart required" : "YabaiControl")
            .accessibilityLabel(service.isUpdatePendingRestart ? "YabaiControl, update ready, restart required" : "YabaiControl")
        }
        .menuBarExtraStyle(.window)

        // Configuration / Settings Window
        Window("Yabai & skhd Configuration", id: "settings") {
            SettingsView()
                .environmentObject(service)
        }
        .defaultSize(width: 780, height: 560)
        .windowResizability(.contentSize)
    }
}
