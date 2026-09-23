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
}
