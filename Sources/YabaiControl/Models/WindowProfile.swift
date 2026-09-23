import Foundation

public struct WindowProfile: Identifiable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var subtitle: String
    public var icon: String
    public var layout: YabaiLayout
    public var windowGap: Int
    public var padding: Int
    public var splitRatio: Double
    public var focusFollowsMouse: FocusFollowsMouseMode
    public var windowOpacity: Bool
    public var activeOpacity: Double

    public init(id: String, name: String, subtitle: String, icon: String, layout: YabaiLayout, windowGap: Int, padding: Int, splitRatio: Double = 0.5, focusFollowsMouse: FocusFollowsMouseMode = .off, windowOpacity: Bool = false, activeOpacity: Double = 1.0) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.icon = icon
        self.layout = layout
        self.windowGap = windowGap
        self.padding = padding
        self.splitRatio = splitRatio
        self.focusFollowsMouse = focusFollowsMouse
        self.windowOpacity = windowOpacity
        self.activeOpacity = activeOpacity
    }

    public static let presets: [WindowProfile] = [
        WindowProfile(
            id: "balanced",
            name: "Balanced",
            subtitle: "Clean 8px gaps, autotiling BSP",
            icon: "rectangle.split.2x2",
            layout: .bsp,
            windowGap: 8,
            padding: 8,
            splitRatio: 0.5,
            focusFollowsMouse: .off
        ),
        WindowProfile(
            id: "coding",
            name: "Coding & Dev",
            subtitle: "Tight 4px gaps, 65/35 split, auto-raise",
            icon: "curlybraces",
            layout: .bsp,
            windowGap: 4,
            padding: 4,
            splitRatio: 0.65,
            focusFollowsMouse: .autoraise
        ),
        WindowProfile(
            id: "meeting",
            name: "Meeting & Presentation",
            subtitle: "Floating layout, no tiling, full opacity",
            icon: "person.2.fill",
            layout: .float,
            windowGap: 0,
            padding: 0,
            splitRatio: 0.5,
            focusFollowsMouse: .off,
            windowOpacity: false,
            activeOpacity: 1.0
        ),
        WindowProfile(
            id: "ultrawide",
            name: "Ultrawide",
            subtitle: "Spacious 16px gaps, generous margins",
            icon: "display.2",
            layout: .bsp,
            windowGap: 14,
            padding: 24,
            splitRatio: 0.5,
            focusFollowsMouse: .autofocus
        ),
        WindowProfile(
            id: "stack",
            name: "Deep Focus Stack",
            subtitle: "Stack tabs, full screen real estate",
            icon: "square.stack.3d.up",
            layout: .stack,
            windowGap: 4,
            padding: 4,
            splitRatio: 0.5
        )
    ]
}
