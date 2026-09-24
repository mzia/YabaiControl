import SwiftUI
import AppKit

/// Manages mouse drag edge trigger zones and translucent snapping preview overlays
@MainActor
public final class EdgeSnappingService: ObservableObject {
    public static let shared = EdgeSnappingService()

    @Published public var activePosition: WindowSnapPosition? = nil
    private var previewWindow: NSWindow?
    public var isEnabled: Bool = true

    public init() {}

    @discardableResult
    private func ensurePreviewWindow() -> NSWindow {
        if let window = previewWindow { return window }
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.ignoresMouseEvents = true
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        let hosting = NSHostingView(rootView: SnapPreviewBoxView())
        window.contentView = hosting
        self.previewWindow = window
        return window
    }

    /// Tests cursor position against screen edge boundaries and updates preview overlay
    public func handleCursorMove(at point: CGPoint) {
        guard isEnabled else {
            hidePreview()
            return
        }

        guard let screen = NSScreen.screens.first(where: { NSPointInRect(point, $0.frame) }) else {
            hidePreview()
            return
        }

        let visibleFrame = screen.visibleFrame
        if let detected = WindowSnapPosition.triggerPosition(for: point, in: visibleFrame, threshold: 24) {
            showPreview(for: detected, in: visibleFrame)
        } else {
            hidePreview()
        }
    }

    /// Displays the translucent snap preview overlay at the target position
    public func showPreview(for position: WindowSnapPosition, in screenRect: CGRect) {
        activePosition = position
        let window = ensurePreviewWindow()

        let rect = position.targetRect(in: screenRect)
        window.setFrame(rect, display: true, animate: false)
        if !window.isVisible {
            window.alphaValue = 0.0
            window.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                window.animator().alphaValue = 1.0
            }
        }
    }

    /// Hides the snap preview overlay
    public func hidePreview() {
        activePosition = nil
        guard let window = previewWindow, window.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            window.animator().alphaValue = 0.0
        }, completionHandler: {
            Task { @MainActor in
                window.orderOut(nil)
            }
        })
    }

    /// Applies the snap action to the currently focused window if a zone is active
    @discardableResult
    public func commitSnap() -> WindowSnapPosition? {
        guard let pos = activePosition else { return nil }
        hidePreview()
        return pos
    }
}

/// Translucent preview box shown when hovering near screen edge zones
public struct SnapPreviewBoxView: View {
    public init() {}

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentColor.opacity(0.18))
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.6), lineWidth: 2)
        }
        .padding(8)
    }
}
