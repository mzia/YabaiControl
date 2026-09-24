import Foundation

public struct YabaiRule: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var app: String
    public var title: String
    public var role: String
    public var space: Int?
    public var display: Int?
    public var manage: Bool?      // true = tile, false = float, nil = default
    public var sticky: Bool?      // visible on all spaces
    public var opacity: Double?   // 0.0 to 1.0
    public var subLayer: String?  // "below", "normal", "above"
    public var isEnabled: Bool

    public init(
        id: UUID = UUID(),
        app: String = "",
        title: String = "",
        role: String = "",
        space: Int? = nil,
        display: Int? = nil,
        manage: Bool? = nil,
        sticky: Bool? = nil,
        opacity: Double? = nil,
        subLayer: String? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.app = app
        self.title = title
        self.role = role
        self.space = space
        self.display = display
        self.manage = manage
        self.sticky = sticky
        self.opacity = opacity
        self.subLayer = subLayer
        self.isEnabled = isEnabled
    }

    /// Generates the yabai CLI rule command line (e.g. `yabai -m rule --add app="^Slack$" space=3`)
    public var commandArguments: [String] {
        var args = ["rule", "--add"]

        if !app.isEmpty {
            args.append("app=^\(app)$")
        }
        if !title.isEmpty {
            args.append("title=^\(title)$")
        }
        if !role.isEmpty {
            args.append("role=^\(role)$")
        }
        if let space = space {
            args.append("space=\(space)")
        }
        if let display = display {
            args.append("display=\(display)")
        }
        if let manage = manage {
            args.append("manage=\(manage ? "on" : "off")")
        }
        if let sticky = sticky {
            args.append("sticky=\(sticky ? "on" : "off")")
        }
        if let opacity = opacity {
            args.append("opacity=\(String(format: "%.2f", opacity))")
        }
        if let subLayer = subLayer, !subLayer.isEmpty {
            args.append("sub-layer=\(subLayer)")
        }

        return args
    }

    /// Formatted rule string for ~/.yabairc
    public var ruleLine: String {
        var parts: [String] = []
        if !app.isEmpty {
            parts.append("app=\"^\(app)$\"")
        }
        if !title.isEmpty {
            parts.append("title=\"^\(title)$\"")
        }
        if !role.isEmpty {
            parts.append("role=\"^\(role)$\"")
        }
        if let space = space {
            parts.append("space=\(space)")
        }
        if let display = display {
            parts.append("display=\(display)")
        }
        if let manage = manage {
            parts.append("manage=\(manage ? "on" : "off")")
        }
        if let sticky = sticky {
            parts.append("sticky=\(sticky ? "on" : "off")")
        }
        if let opacity = opacity {
            parts.append("opacity=\(String(format: "%.2f", opacity))")
        }
        if let subLayer = subLayer, !subLayer.isEmpty {
            parts.append("sub-layer=\(subLayer)")
        }

        return "yabai -m rule --add " + parts.joined(separator: " ")
    }

    /// Summary badge text for UI display
    public var summaryText: String {
        var badges: [String] = []
        if let space = space {
            badges.append("Space \(space)")
        }
        if let display = display {
            badges.append("Display \(display)")
        }
        if let manage = manage {
            badges.append(manage ? "Tiled" : "Floating")
        }
        if sticky == true {
            badges.append("Sticky")
        }
        if let subLayer = subLayer {
            badges.append("Layer: \(subLayer)")
        }
        if let opacity = opacity {
            badges.append("\(Int(opacity * 100))% Opacity")
        }
        return badges.isEmpty ? "No actions" : badges.joined(separator: " • ")
    }

    /// Default starter rules
    public static var defaultRules: [YabaiRule] {
        [
            YabaiRule(app: "System Settings", manage: false),
            YabaiRule(app: "Calculator", manage: false),
            YabaiRule(app: "1Password", manage: false),
            YabaiRule(app: "Archive Utility", manage: false),
            YabaiRule(app: "QuickTime Player", manage: false),
            YabaiRule(title: "Picture in Picture", sticky: true, subLayer: "above"),
            YabaiRule(app: "Finder", title: "Copy", manage: false)
        ]
    }
}
