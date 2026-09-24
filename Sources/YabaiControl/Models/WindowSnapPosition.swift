import Foundation

public enum WindowSnapPosition: String, CaseIterable, Identifiable, Sendable {
    case leftHalf = "Left Half"
    case rightHalf = "Right Half"
    case topHalf = "Top Half"
    case bottomHalf = "Bottom Half"
    case topLeft = "Top Left"
    case topRight = "Top Right"
    case bottomLeft = "Bottom Left"
    case bottomRight = "Bottom Right"
    case center = "Center"
    case maximize = "Maximize"

    public var id: String { rawValue }

    public var gridCommand: String {
        switch self {
        case .leftHalf: return "1:2:0:0:1:1"
        case .rightHalf: return "1:2:1:0:1:1"
        case .topHalf: return "2:1:0:0:1:1"
        case .bottomHalf: return "2:1:0:1:1:1"
        case .topLeft: return "2:2:0:0:1:1"
        case .topRight: return "2:2:1:0:1:1"
        case .bottomLeft: return "2:2:0:1:1:1"
        case .bottomRight: return "2:2:1:1:1:1"
        case .center: return "4:4:1:1:2:2"
        case .maximize: return "1:1:0:0:1:1"
        }
    }

    public var iconName: String {
        switch self {
        case .leftHalf: return "rectangle.leadinghalf.filled"
        case .rightHalf: return "rectangle.trailinghalf.filled"
        case .topHalf: return "rectangle.tophalf.filled"
        case .bottomHalf: return "rectangle.bottomhalf.filled"
        case .topLeft: return "rectangle.inset.topleft.filled"
        case .topRight: return "rectangle.inset.topright.filled"
        case .bottomLeft: return "rectangle.inset.bottomleft.filled"
        case .bottomRight: return "rectangle.inset.bottomright.filled"
        case .center: return "rectangle.center.inset.filled"
        case .maximize: return "rectangle.fill"
        }
    }

    /// Computes the exact target screen frame in macOS coordinates (bottom-left origin)
    public func targetRect(in screenRect: CGRect) -> CGRect {
        let minX = screenRect.minX
        let minY = screenRect.minY
        let midX = screenRect.midX
        let midY = screenRect.midY
        let halfW = screenRect.width / 2
        let halfH = screenRect.height / 2

        switch self {
        case .leftHalf:
            return CGRect(x: minX, y: minY, width: halfW, height: screenRect.height)
        case .rightHalf:
            return CGRect(x: midX, y: minY, width: halfW, height: screenRect.height)
        case .topHalf:
            return CGRect(x: minX, y: midY, width: screenRect.width, height: halfH)
        case .bottomHalf:
            return CGRect(x: minX, y: minY, width: screenRect.width, height: halfH)
        case .topLeft:
            return CGRect(x: minX, y: midY, width: halfW, height: halfH)
        case .topRight:
            return CGRect(x: midX, y: midY, width: halfW, height: halfH)
        case .bottomLeft:
            return CGRect(x: minX, y: minY, width: halfW, height: halfH)
        case .bottomRight:
            return CGRect(x: midX, y: minY, width: halfW, height: halfH)
        case .center:
            return CGRect(
                x: minX + screenRect.width * 0.15,
                y: minY + screenRect.height * 0.15,
                width: screenRect.width * 0.7,
                height: screenRect.height * 0.7
            )
        case .maximize:
            return screenRect
        }
    }

    /// Detects if a cursor position triggers a snap action along the screen boundaries
    public static func triggerPosition(for point: CGPoint, in screenRect: CGRect, threshold: CGFloat = 20) -> WindowSnapPosition? {
        let isNearLeft = point.x <= screenRect.minX + threshold
        let isNearRight = point.x >= screenRect.maxX - threshold
        let isNearTop = point.y >= screenRect.maxY - threshold
        let isNearBottom = point.y <= screenRect.minY + threshold

        // Corner zones have priority
        if isNearTop && isNearLeft {
            return .topLeft
        } else if isNearTop && isNearRight {
            return .topRight
        } else if isNearBottom && isNearLeft {
            return .bottomLeft
        } else if isNearBottom && isNearRight {
            return .bottomRight
        }

        // Edge zones
        if isNearTop {
            return .maximize
        } else if isNearLeft {
            return .leftHalf
        } else if isNearRight {
            return .rightHalf
        } else if isNearBottom {
            return .bottomHalf
        }

        return nil
    }
}
