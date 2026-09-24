import Foundation
import AppKit

public enum ScratchpadSizePreset: String, CaseIterable, Identifiable, Codable, Sendable {
    case topDrawer = "Top Drawer (45%)"
    case centerFloating = "Center Floating (70%)"
    case rightSidebar = "Right Sidebar (40%)"

    public var id: String { rawValue }

    public var gridCommand: String {
        switch self {
        case .topDrawer: return "10:10:0:1:10:4"
        case .centerFloating: return "10:10:1:1:8:8"
        case .rightSidebar: return "1:10:6:0:4:10"
        }
    }
}

@MainActor
public final class ScratchpadService: ObservableObject {
    public static let shared = ScratchpadService()

    @Published public var isVisible: Bool = false
    public var lastWindowId: Int? = nil

    public init() {}

    /// Toggles the scratchpad application window
    public func toggleScratchpad(
        appName: String = "Terminal",
        preset: ScratchpadSizePreset = .topDrawer,
        yabaiService: YabaiService = YabaiService.shared
    ) {
        guard yabaiService.isYabaiRunning else {
            yabaiService.statusMessage = "Cannot summon scratchpad: yabai daemon is not running."
            return
        }

        // Query active windows to find target app
        let res = yabaiService.runYabaiCommand(["query", "--windows"])
        guard res.status == 0, let data = res.output.data(using: .utf8) else {
            launchApp(appName)
            return
        }

        let decoder = JSONDecoder()
        guard let windows = try? decoder.decode([YabaiWindow].self, from: data) else {
            launchApp(appName)
            return
        }

        // Search for existing window of target app
        let matching = windows.filter { $0.app.lowercased() == appName.lowercased() }

        guard let targetWindow = matching.first else {
            launchApp(appName)
            yabaiService.statusMessage = "Launching \(appName) as scratchpad..."
            return
        }

        let windowId = targetWindow.id
        self.lastWindowId = windowId

        if targetWindow.hasFocus && targetWindow.isSticky {
            // Dismiss scratchpad
            _ = yabaiService.runYabaiCommand(["window", "\(windowId)", "--toggle", "sticky"])
            _ = yabaiService.runYabaiCommand(["window", "--focus", "recent"])
            self.isVisible = false
            yabaiService.statusMessage = "Dismissed \(appName) scratchpad."
        } else {
            // Summon scratchpad to active space & focus
            _ = yabaiService.runYabaiCommand(["window", "\(windowId)", "--space", "mouse"])
            if !targetWindow.isSticky {
                _ = yabaiService.runYabaiCommand(["window", "\(windowId)", "--toggle", "sticky"])
            }
            _ = yabaiService.runYabaiCommand(["window", "\(windowId)", "--sub-layer", "above"])
            _ = yabaiService.runYabaiCommand(["window", "\(windowId)", "--grid", preset.gridCommand])
            _ = yabaiService.runYabaiCommand(["window", "\(windowId)", "--focus"])
            self.isVisible = true
            yabaiService.statusMessage = "Summoned \(appName) scratchpad."
        }
    }

    private func launchApp(_ appName: String) {
        if let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.\(appName.lowercased())") ??
                         NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.googlecode.\(appName.lowercased())") {
            NSWorkspace.shared.openApplication(at: appUrl, configuration: NSWorkspace.OpenConfiguration())
        } else {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            proc.arguments = ["-a", appName]
            try? proc.run()
        }
    }
}
