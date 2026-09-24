import SwiftUI
import AppKit

public struct ShortcutConflict: Equatable {
    public let shortcut: String
    public let systemFeature: String
}

public struct ShortcutConflictDetector {
    public static let knownConflicts: [String: String] = [
        "cmd+space": "Spotlight Search",
        "cmd+alt+space": "Finder Search Window",
        "cmd+tab": "macOS App Switcher",
        "cmd+q": "Quit Application",
        "cmd+w": "Close Window",
        "cmd+m": "Minimize Window",
        "cmd+h": "Hide Application",
        "ctrl+up": "Mission Control",
        "ctrl+down": "Application Windows / Exposé",
        "ctrl+left": "Move Left a Space",
        "ctrl+right": "Move Right a Space",
        "alt+space": "Alfred / Raycast / Launcher",
        "cmd+shift+3": "Full Screen Capture",
        "cmd+shift+4": "Selection Screen Capture",
        "cmd+shift+5": "Screen Recording & Capture Options"
    ]

    public static func checkConflict(modifier: String, key: String) -> String? {
        let normalizedMod = modifier
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "shift", with: "shift+")
            .replacingOccurrences(of: "ctrl", with: "ctrl+")
            .replacingOccurrences(of: "alt", with: "alt+")
            .replacingOccurrences(of: "cmd", with: "cmd+")
            .trimmingCharacters(in: CharacterSet(charactersIn: "+"))

        let combo = "\(normalizedMod)+\(key.lowercased())"
            .replacingOccurrences(of: "++", with: "+")

        for (known, desc) in knownConflicts {
            if combo == known {
                return desc
            }
        }
        return nil
    }
}

@MainActor
public final class ShortcutRecorderSession: ObservableObject {
    public static let shared = ShortcutRecorderSession()

    @Published public var activeRecordingId: String? = nil
    private var eventMonitor: Any?

    public init() {}

    public func isRecording(id: String) -> Bool {
        activeRecordingId == id
    }

    public func startRecording(id: String, onKeyCaptured: @escaping (String) -> Void) {
        stopRecording()
        activeRecordingId = id

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self, self.activeRecordingId == id else { return event }

            // Handle escape to cancel recording
            if event.keyCode == 53 {
                Task { @MainActor in
                    self.stopRecording()
                }
                return nil
            }

            let newKey = self.keyString(for: event)
            if !newKey.isEmpty {
                Task { @MainActor in
                    onKeyCaptured(newKey)
                    self.stopRecording()
                }
                return nil
            }
            return event
        }
    }

    public func stopRecording() {
        activeRecordingId = nil
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func keyString(for event: NSEvent) -> String {
        switch event.keyCode {
        case 123: return "left"
        case 124: return "right"
        case 125: return "down"
        case 126: return "up"
        case 36: return "return"
        case 48: return "tab"
        case 49: return "space"
        default:
            if let chars = event.charactersIgnoringModifiers?.lowercased(), !chars.isEmpty {
                let first = chars.first!
                if first.isLetter || first.isNumber {
                    return String(first)
                }
            }
            return ""
        }
    }
}

public struct ShortcutRecorderView: View {
    public var id: String
    public var label: String
    @Binding public var key: String
    public var modifier: String
    public var width: CGFloat

    @ObservedObject private var session = ShortcutRecorderSession.shared

    public init(id: String, label: String = "", key: Binding<String>, modifier: String = "alt", width: CGFloat = 65) {
        self.id = id
        self.label = label
        self._key = key
        self.modifier = modifier
        self.width = width
    }

    private var isRecording: Bool {
        session.isRecording(id: id)
    }

    private var conflictMessage: String? {
        ShortcutConflictDetector.checkConflict(modifier: modifier, key: key)
    }

    public var body: some View {
        HStack(spacing: 4) {
            if !label.isEmpty {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
            }

            Button {
                if isRecording {
                    session.stopRecording()
                } else {
                    session.startRecording(id: id) { capturedKey in
                        key = capturedKey
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    if isRecording {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 5, height: 5)
                        Text("Press...")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    } else {
                        Text(displayKey(key))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(isRecording ? Color.accentColor : Color.primary)
                    }
                }
                .frame(width: width, height: 20)
                .background(isRecording ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isRecording ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isRecording ? 1.5 : 1)
                )
            }
            .buttonStyle(.plain)

            if let conflict = conflictMessage {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                    .font(.system(size: 11))
                    .help("Conflict: Matches default '\(conflict)'")
            }
        }
    }

    private func displayKey(_ raw: String) -> String {
        switch raw.lowercased() {
        case "left": return "← Left"
        case "right": return "→ Right"
        case "up": return "↑ Up"
        case "down": return "↓ Down"
        case "return", "enter": return "⏎ Return"
        case "tab": return "⇥ Tab"
        case "space": return "␣ Space"
        case "": return "None"
        default: return raw.uppercased()
        }
    }
}
