import Foundation
import AppKit

public enum DisplayProfileType: String, CaseIterable, Identifiable, Sendable {
    case ultrawide = "Ultrawide (21:9 / 32:9)"
    case portrait = "Portrait / Vertical"
    case standard = "Standard (16:10 / 16:9)"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .ultrawide: return "display.2"
        case .portrait: return "iphone"
        case .standard: return "laptopcomputer"
        }
    }
}

public struct DisplayTuningService: Sendable {
    /// Detects display profile type based on physical screen aspect ratio
    public static func detectDisplayProfile(width: CGFloat, height: CGFloat) -> DisplayProfileType {
        guard height > 0 else { return .standard }
        let ratio = width / height

        if ratio >= 2.0 {
            return .ultrawide
        } else if ratio < 1.0 {
            return .portrait
        } else {
            return .standard
        }
    }

    /// Computes recommended side padding based on display aspect ratio
    public static func recommendedSidePadding(
        for profile: DisplayProfileType,
        basePadding: Int = 8,
        ultrawidePadding: Int = 40
    ) -> (left: Int, right: Int) {
        switch profile {
        case .ultrawide:
            return (ultrawidePadding, ultrawidePadding)
        case .portrait:
            return (basePadding, basePadding)
        case .standard:
            return (basePadding, basePadding)
        }
    }

    /// Scans connected screens and returns the primary display profile
    @MainActor
    public static func currentPrimaryDisplayProfile() -> DisplayProfileType {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            return .standard
        }
        return detectDisplayProfile(width: screen.frame.width, height: screen.frame.height)
    }
}
