import SwiftUI
import AppKit

/// Manages the floating, non-activating Notch HUD window
@MainActor
public final class NotchHUDManager: ObservableObject {
    public static let shared = NotchHUDManager()

    @Published public var currentData = NotchHUDData()
    @Published public var isVisible: Bool = false

    private var hudWindow: NSWindow?
    private var dismissTimer: Timer?
    public var isEnabled: Bool = true

    public init() {
        setupWindow()
    }

    private func setupWindow() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 44),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.ignoresMouseEvents = true
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        let hosting = NSHostingView(rootView: NotchHUDHostingRoot(manager: self))
        panel.contentView = hosting
        self.hudWindow = panel
    }

    /// Displays the HUD for the given window, space, and layout parameters
    public func show(appName: String, title: String, space: Int, layout: YabaiLayout, icon: NSImage? = nil) {
        guard isEnabled else { return }

        currentData = NotchHUDData(
            appName: appName,
            windowTitle: title,
            spaceIndex: space,
            layout: layout,
            appIcon: icon
        )

        positionWindow()

        dismissTimer?.invalidate()
        if let window = hudWindow {
            if !isVisible {
                window.alphaValue = 0.0
                window.orderFrontRegardless()
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.2
                    window.animator().alphaValue = 1.0
                }
                isVisible = true
            }
        }

        // Auto-fade after 2.2 seconds
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 2.2, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.dismiss()
            }
        }
    }

    /// Dismisses the HUD with a smooth fade-out
    public func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        guard let window = hudWindow, isVisible else { return }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            window.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            Task { @MainActor in
                window.orderOut(nil)
                self?.isVisible = false
            }
        })
    }

    private func positionWindow() {
        guard let window = hudWindow else { return }
        let screen = NSScreen.main ?? NSScreen.screens.first

        guard let targetScreen = screen else { return }
        let screenFrame = targetScreen.frame
        let visibleFrame = targetScreen.visibleFrame

        // Detect if active screen has a physical camera notch
        let hasNotch: Bool
        if #available(macOS 12.0, *) {
            hasNotch = targetScreen.safeAreaInsets.top > 0
        } else {
            hasNotch = false
        }

        let hudWidth: CGFloat = 340
        let hudHeight: CGFloat = 44
        let posX = screenFrame.midX - (hudWidth / 2)

        let posY: CGFloat
        if hasNotch {
            // Place directly beneath the notch area
            posY = screenFrame.maxY - (targetScreen.safeAreaInsets.top) - hudHeight + 4
        } else {
            // Float top-center with small margin below the menu bar
            posY = visibleFrame.maxY - hudHeight - 8
        }

        window.setFrame(NSRect(x: posX, y: posY, width: hudWidth, height: hudHeight), display: true)
    }
}

/// Root host view for the notch HUD
private struct NotchHUDHostingRoot: View {
    @ObservedObject var manager: NotchHUDManager

    var body: some View {
        NotchHUDView(data: manager.currentData)
    }
}
