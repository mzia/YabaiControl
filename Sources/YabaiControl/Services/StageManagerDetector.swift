import Foundation

/// Detects macOS Stage Manager state from com.apple.WindowManager
public struct StageManagerDetector: Sendable {
    /// Pluggable preference reader for unit testing without altering system configuration
    public static nonisolated(unsafe) var preferenceReader: (@Sendable (String, String) -> Bool?) = { suite, key in
        CFPreferencesAppSynchronize(suite as CFString)
        var exists: DarwinBoolean = false
        let val = CFPreferencesGetAppBooleanValue(key as CFString, suite as CFString, &exists)
        return exists.boolValue ? val : nil
    }

    /// Returns true if Apple Stage Manager (GloballyEnabled) is currently active on macOS
    public static func isStageManagerEnabled() -> Bool {
        preferenceReader("com.apple.WindowManager", "GloballyEnabled") ?? false
    }
}
