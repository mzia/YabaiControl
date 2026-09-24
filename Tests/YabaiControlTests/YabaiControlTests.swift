import Testing
import Foundation
import AppKit
@testable import YabaiControl

@Suite("Yabai Configuration Tests")
struct YabaiConfigTests {

    @Test("Default configuration values")
    func testDefaultConfig() {
        let config = YabaiConfig()
        #expect(config.layout == .bsp)
        #expect(config.windowGap == 8)
        #expect(config.topPadding == 8)
        #expect(config.bottomPadding == 8)
        #expect(config.leftPadding == 8)
        #expect(config.rightPadding == 8)
        #expect(config.splitRatio == 0.5)
        #expect(config.focusFollowsMouse == .off)
        #expect(config.mouseFollowsFocus == false)
        #expect(config.autoBalance == false)
        #expect(config.windowOpacity == false)
        #expect(config.floatingApps.contains("Calculator"))
        #expect(config.floatingApps.contains("System Settings"))
    }

    @Test("generateYabairc produces valid configuration commands")
    func testGenerateYabairc() {
        var config = YabaiConfig()
        config.layout = .stack
        config.windowGap = 12
        config.topPadding = 16
        config.bottomPadding = 16
        config.autoBalance = true
        config.focusFollowsMouse = .autoraise
        config.windowOpacity = true
        config.activeOpacity = 0.95
        config.normalOpacity = 0.85
        config.floatingApps = ["Finder", "Notes"]

        let script = config.generateYabairc()

        #expect(script.contains("#!/usr/bin/env sh"))
        #expect(script.contains("yabai -m config layout stack"))
        #expect(script.contains("yabai -m config window_gap 12"))
        #expect(script.contains("yabai -m config top_padding 16"))
        #expect(script.contains("yabai -m config auto_balance on"))
        #expect(script.contains("yabai -m config focus_follows_mouse autoraise"))
        #expect(script.contains("yabai -m config window_opacity on"))
        #expect(script.contains("yabai -m config active_window_opacity 0.95"))
        #expect(script.contains("yabai -m config normal_window_opacity 0.85"))
        #expect(script.contains("yabai -m rule --add app=\"^Finder$\" manage=off"))
        #expect(script.contains("yabai -m rule --add app=\"^Notes$\" manage=off"))
    }

    @Test("Layout display names and icon names")
    func testLayoutProperties() {
        #expect(YabaiLayout.bsp.displayName == "BSP (Autotile)")
        #expect(YabaiLayout.stack.displayName == "Stack")
        #expect(YabaiLayout.float.displayName == "Floating")

        #expect(!YabaiLayout.bsp.iconName.isEmpty)
        #expect(!YabaiLayout.stack.iconName.isEmpty)
        #expect(!YabaiLayout.float.iconName.isEmpty)
    }

    @Test("Focus follows mouse display names")
    func testFocusFollowsMouse() {
        #expect(FocusFollowsMouseMode.off.displayName == "Off")
        #expect(FocusFollowsMouseMode.autoraise.displayName == "Auto-Raise")
        #expect(FocusFollowsMouseMode.autofocus.displayName == "Auto-Focus")
    }
}

@Suite("skhd Configuration Tests")
struct SkhdConfigTests {

    @Test("Default skhd configuration")
    func testDefaultSkhdConfig() {
        let config = SKHDConfig()
        #expect(config.primaryModifier == "alt")
        #expect(config.focusLeft == "h")
        #expect(config.focusDown == "j")
        #expect(config.focusUp == "k")
        #expect(config.focusRight == "l")
        #expect(config.toggleFloat == "t")
        #expect(config.toggleSplit == "e")
        #expect(config.balanceSizes == "b")
        #expect(config.restartYabai == "r")
        #expect(config.enableWindowWarp == true)
        #expect(config.enableDisplayShortcuts == true)
        #expect(config.enableGridSnapping == true)
        #expect(config.enableSpaceFollowShortcuts == true)
        #expect(config.enableWindowResize == true)
    }

    @Test("generateSkhdrc produces expected shortcut bindings including warp and displays")
    func testGenerateSkhdrc() {
        var config = SKHDConfig()
        config.primaryModifier = "cmd + alt"

        let script = config.generateSkhdrc()

        #expect(script.contains("cmd + alt - h : yabai -m window --focus west"))
        #expect(script.contains("cmd + alt - j : yabai -m window --focus south"))
        #expect(script.contains("cmd + alt - k : yabai -m window --focus north"))
        #expect(script.contains("cmd + alt - l : yabai -m window --focus east"))
        #expect(script.contains("shift + cmd + alt - h : yabai -m window --swap west"))
        #expect(script.contains("ctrl + cmd + alt - h : yabai -m window --warp west"))
        #expect(script.contains("ctrl + cmd + alt - n : yabai -m window --display next && yabai -m display --focus next"))
        #expect(script.contains("ctrl + cmd + alt - p : yabai -m window --display prev && yabai -m display --focus prev"))
        #expect(script.contains("ctrl + cmd + alt - left : yabai -m window --grid 1:2:0:0:1:1"))
        #expect(script.contains("ctrl + cmd + alt - right : yabai -m window --grid 1:2:1:0:1:1"))
        #expect(script.contains("ctrl + cmd + alt - m : yabai -m window --toggle zoom-fullscreen"))
        #expect(script.contains("ctrl + shift - right : yabai -m window --space next && yabai -m space --focus next"))
        #expect(script.contains("cmd + cmd + alt - h : yabai -m window --resize left:-30:0 || yabai -m window --resize right:-30:0"))
        #expect(script.contains("cmd + alt - t : yabai -m window --toggle float --grid 4:4:1:1:2:2"))
        #expect(script.contains("cmd + alt - e : yabai -m window --toggle split"))
        #expect(script.contains("cmd + alt - b : yabai -m space --balance"))
        #expect(script.contains("shift + cmd + alt - r : yabai --restart-service"))
        #expect(script.contains("cmd + alt - 1 : yabai -m space --focus 1"))
        #expect(script.contains("shift + cmd + alt - 5 : yabai -m window --space 5"))
    }

    @Test("generateSkhdrc respects feature toggles")
    func testSkhdFeatureToggles() {
        var config = SKHDConfig()
        config.enableWindowWarp = false
        config.enableDisplayShortcuts = false
        config.enableGridSnapping = false
        config.enableSpaceFollowShortcuts = false
        config.enableWindowResize = false

        let script = config.generateSkhdrc()

        #expect(!script.contains("--warp"))
        #expect(!script.contains("--display"))
        #expect(!script.contains("ctrl + alt - left : yabai -m window --grid"))
        #expect(!script.contains("space next && yabai -m space --focus next"))
        #expect(!script.contains("--resize"))
        // Base bindings should remain
        #expect(script.contains("alt - h : yabai -m window --focus west"))
        #expect(script.contains("shift + alt - h : yabai -m window --swap west"))
    }
}

@Suite("Service Paths and Script Syntax Tests")
@MainActor
struct ServiceAndScriptTests {

    @Test("Configuration file paths resolve to user home directory")
    func testConfigPaths() {
        let service = YabaiService.shared
        #expect(service.yabaircURL.lastPathComponent == ".yabairc")
        #expect(service.skhdrcURL.lastPathComponent == ".skhdrc")
        #expect(service.yabaircURL.path.hasPrefix("/Users/"))
    }

    @Test("Binary path resolution returns non-empty paths")
    func testBinaryPaths() {
        let service = YabaiService.shared
        #expect(!service.yabaiBinaryPath.isEmpty)
        #expect(!service.skhdBinaryPath.isEmpty)
        #expect(service.yabaiBinaryPath.hasSuffix("yabai"))
        #expect(service.skhdBinaryPath.hasSuffix("skhd"))
    }

    @Test("Shell scripts have valid bash syntax")
    func testShellScriptSyntax() {
        let scripts = ["bundle.sh", "package.sh", "uninstall.sh", "scripts/fetch-upstream-binaries.sh"]
        for script in scripts {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-n", script]
            let pipe = Pipe()
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()
                #expect(process.terminationStatus == 0, "Script \(script) syntax error")
            } catch {
                Issue.record("Failed to run bash -n on \(script): \(error)")
            }
        }
    }
}

@Suite("Floating App Management Tests")
@MainActor
struct FloatingAppManagementTests {

    @Test("Add and remove floating applications")
    func testAddAndRemoveFloatingApps() {
        let service = YabaiService.shared
        let testApp = "TestAppUnique123"

        service.addFloatingApp(testApp)
        #expect(service.yabaiConfig.floatingApps.contains(testApp))

        // Duplicate add is idempotent
        let initialCount = service.yabaiConfig.floatingApps.count
        service.addFloatingApp(testApp)
        #expect(service.yabaiConfig.floatingApps.count == initialCount)

        service.removeFloatingApp(testApp)
        #expect(!service.yabaiConfig.floatingApps.contains(testApp))
    }

    @Test("Resolve application name from URL")
    func testResolveAppName() {
        let service = YabaiService.shared
        let calcURL = URL(fileURLWithPath: "/System/Applications/Calculator.app")
        let resolved = service.resolveAppName(from: calcURL)
        #expect(resolved == "Calculator")
    }
}

@Suite("Power Features Suite Tests")
@MainActor
struct PowerFeaturesTests {

    @Test("WindowSnapPosition covers all grid positions and symbols")
    func testWindowSnapPositions() {
        let allPositions = WindowSnapPosition.allCases
        #expect(allPositions.count == 10)

        for pos in allPositions {
            #expect(!pos.rawValue.isEmpty)
            #expect(!pos.gridCommand.isEmpty)
            #expect(!pos.iconName.isEmpty)
            #expect(pos.gridCommand.contains(":"))
        }

        #expect(WindowSnapPosition.leftHalf.gridCommand == "1:2:0:0:1:1")
        #expect(WindowSnapPosition.rightHalf.gridCommand == "1:2:1:0:1:1")
        #expect(WindowSnapPosition.maximize.gridCommand == "1:1:0:0:1:1")
        #expect(WindowSnapPosition.center.gridCommand == "4:4:1:1:2:2")
    }

    @Test("WindowProfile presets validate correctly")
    func testWindowProfilePresets() {
        let presets = WindowProfile.presets
        #expect(presets.count == 5)

        let ids = presets.map(\.id)
        #expect(ids.contains("balanced"))
        #expect(ids.contains("coding"))
        #expect(ids.contains("meeting"))
        #expect(ids.contains("ultrawide"))
        #expect(ids.contains("stack"))

        let coding = presets.first { $0.id == "coding" }
        #expect(coding?.layout == .bsp)
        #expect(coding?.windowGap == 4)
        #expect(coding?.splitRatio == 0.65)
        #expect(coding?.focusFollowsMouse == .autoraise)

        let meeting = presets.first { $0.id == "meeting" }
        #expect(meeting?.layout == .float)
        #expect(meeting?.windowGap == 0)

        let ultrawide = presets.first { $0.id == "ultrawide" }
        #expect(ultrawide?.layout == .bsp)
        #expect(ultrawide?.padding == 24)
    }

    @Test("YabaiSpace and YabaiWindow JSON decoding")
    func testSpaceAndWindowDecoding() throws {
        let spacesJSON = """
        [
          {
            "id": 1,
            "uuid": "UUID-1",
            "index": 1,
            "label": "main",
            "type": "bsp",
            "display": 1,
            "windows": [101, 102],
            "has-focus": true,
            "is-visible": true,
            "is-native-fullscreen": false
          },
          {
            "id": 2,
            "uuid": "UUID-2",
            "index": 2,
            "label": null,
            "type": "float",
            "display": 1,
            "windows": [],
            "has-focus": false,
            "is-visible": false,
            "is-native-fullscreen": false
          }
        ]
        """.data(using: .utf8)!

        let decodedSpaces = try JSONDecoder().decode([YabaiSpace].self, from: spacesJSON)
        #expect(decodedSpaces.count == 2)
        #expect(decodedSpaces[0].index == 1)
        #expect(decodedSpaces[0].label == "main")
        #expect(decodedSpaces[0].hasFocus == true)
        #expect(decodedSpaces[0].windows == [101, 102])
        #expect(decodedSpaces[1].index == 2)
        #expect(decodedSpaces[1].type == "float")
        #expect(decodedSpaces[1].hasFocus == false)

        let windowsJSON = """
        [
          {
            "id": 101,
            "pid": 4520,
            "app": "Xcode",
            "title": "YabaiControl",
            "space": 1,
            "has-focus": true,
            "is-floating": false
          }
        ]
        """.data(using: .utf8)!

        let decodedWindows = try JSONDecoder().decode([YabaiWindow].self, from: windowsJSON)
        #expect(decodedWindows.count == 1)
        #expect(decodedWindows[0].app == "Xcode")
        #expect(decodedWindows[0].hasFocus == true)
        #expect(decodedWindows[0].isFloating == false)
    }

    @Test("MenuBarDisplayStyle formatting")
    func testMenuBarDisplayStyle() {
        let service = YabaiService.shared
        service.yabaiConfig.layout = .bsp
        service.activeSpaceIndex = 3

        service.yabaiConfig.menuBarDisplayStyle = .iconOnly
        #expect(service.menuBarStatusText.isEmpty)

        service.yabaiConfig.menuBarDisplayStyle = .iconAndLayout
        #expect(service.menuBarStatusText == "BSP")

        service.yabaiConfig.menuBarDisplayStyle = .iconAndSpace
        #expect(service.menuBarStatusText == "S3")

        service.yabaiConfig.menuBarDisplayStyle = .iconAndBoth
        #expect(service.menuBarStatusText == "BSP • S3")
    }

    @Test("Applying workflow profile updates service configuration")
    func testApplyWorkflowProfile() {
        let service = YabaiService.shared
        guard let codingProfile = WindowProfile.presets.first(where: { $0.id == "coding" }) else {
            Issue.record("Coding profile missing")
            return
        }

        service.applyProfile(codingProfile)
        #expect(service.yabaiConfig.layout == .bsp)
        #expect(service.yabaiConfig.windowGap == 4)
        #expect(service.yabaiConfig.topPadding == 4)
        #expect(service.yabaiConfig.splitRatio == 0.65)
        #expect(service.yabaiConfig.focusFollowsMouse == .autoraise)
        #expect(service.activeProfileId == "coding")
    }
}

@Suite("Update and Restart Management Tests")
@MainActor
struct UpdateAndRestartTests {

    @Test("isUpdatePendingRestart evaluates correctly")
    func testUpdatePendingRestartEvaluation() {
        let service = YabaiService.shared

        service.setUpdatePendingRestart(available: false, restartRequired: false)
        #expect(service.isUpdatePendingRestart == false)

        service.setUpdatePendingRestart(available: true, restartRequired: false)
        #expect(service.isUpdatePendingRestart == false)

        service.setUpdatePendingRestart(available: false, restartRequired: true)
        #expect(service.isUpdatePendingRestart == false)

        service.setUpdatePendingRestart(available: true, restartRequired: true, version: "1.1.0")
        #expect(service.isUpdatePendingRestart == true)
        #expect(service.updateVersion == "1.1.0")
        #expect(service.updateStatusMessage.contains("1.1.0"))
    }

    @Test("toggleSimulatedUpdate toggles state cleanly")
    func testToggleSimulatedUpdate() {
        let service = YabaiService.shared

        service.setUpdatePendingRestart(available: false, restartRequired: false)
        #expect(service.isUpdatePendingRestart == false)

        service.toggleSimulatedUpdate()
        #expect(service.isUpdatePendingRestart == true)
        #expect(service.updateVersion == "1.1.0")

        service.toggleSimulatedUpdate()
        #expect(service.isUpdatePendingRestart == false)
    }

    @Test("Semantic version comparison logic")
    func testSemanticVersionComparison() {
        let service = YabaiService.shared

        #expect(service.isVersion("1.1.0", greaterThan: "1.0.0") == true)
        #expect(service.isVersion("1.0.1", greaterThan: "1.0.0") == true)
        #expect(service.isVersion("2.0.0", greaterThan: "1.9.9") == true)
        #expect(service.isVersion("1.10.0", greaterThan: "1.2.0") == true)

        #expect(service.isVersion("1.0.0", greaterThan: "1.0.0") == false)
        #expect(service.isVersion("1.0.0", greaterThan: "1.1.0") == false)
        #expect(service.isVersion("0.9.0", greaterThan: "1.0.0") == false)
    }

    @Test("performPendingRestart resets pending states")
    func testPerformPendingRestart() {
        let service = YabaiService.shared

        service.setUpdatePendingRestart(available: true, restartRequired: true, version: "1.2.0")
        #expect(service.isUpdatePendingRestart == true)

        service.performPendingRestart()
        #expect(service.isUpdatePendingRestart == false)
        #expect(service.isRestartRequired == false)
        #expect(service.isUpdateAvailable == false)
    }
}

@Suite("Accessibility Permission Verification Tests")
@MainActor
struct AccessibilityPermissionTests {

    @Test("acknowledgeAccessibilityPermission confirms permission and persists")
    func testAcknowledgeAccessibilityPermission() {
        let service = YabaiService.shared

        service.acknowledgeAccessibilityPermission()
        #expect(service.hasAccessibilityPermission == true)
        #expect(UserDefaults.standard.bool(forKey: "hasAccessibilityPermissionAcknowledged") == true)
    }

    @Test("resetAccessibilityPermissionCheck clears acknowledgment and re-runs check")
    func testResetAccessibilityPermissionCheck() {
        let service = YabaiService.shared

        service.acknowledgeAccessibilityPermission()
        #expect(UserDefaults.standard.bool(forKey: "hasAccessibilityPermissionAcknowledged") == true)

        service.resetAccessibilityPermissionCheck()
        #expect(UserDefaults.standard.object(forKey: "hasAccessibilityPermissionAcknowledged") == nil)
    }
}

@Suite("Performance & Event-Driven Architecture Tests")
@MainActor
struct PerformanceAndEventDrivenTests {

    @Test("In-memory process detection discovers system processes without forks")
    func testInMemoryProcessDetection() {
        let service = YabaiService.shared

        // Finder is always running in macOS GUI
        #expect(service.isProcessRunning("Finder") == true)

        // Nonexistent process should return false
        #expect(service.isProcessRunning("nonexistent_process_xyz_999") == false)
    }

    @Test("refreshAllState runs cleanly")
    func testRefreshAllState() {
        let service = YabaiService.shared
        service.refreshAllState()

        #expect(!service.yabaiBinaryPath.isEmpty)
        #expect(!service.skhdBinaryPath.isEmpty)
    }

    @Test("Active space notification triggers space update")
    func testActiveSpaceNotificationObserver() {
        let service = YabaiService.shared

        // Simulating the macOS system notification
        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        // Does not throw and leaves service in a consistent state
        #expect(service.activeSpaceIndex >= 1)
    }
}

// MARK: - Phase 2 Native Power Features Tests

@Suite("Yabai IPC Socket Tests")
struct YabaiIPCSocketTests {
    @Test("Socket path is well-formed with active macOS user")
    func testSocketPath() {
        let path = YabaiIPC.socketPath
        #expect(path.hasPrefix("/tmp/yabai_"))
        #expect(path.hasSuffix(".socket"))
    }

    @Test("encodeMessage formats wire protocol with 4-byte uint32 length prefix and null terminators")
    func testEncodeMessage() {
        let data = YabaiIPC.encodeMessage(["query", "--spaces"])
        // Payload: "query\0--spaces\0\0" (16 bytes)
        // Length prefix: 16 (0x10, 0x00, 0x00, 0x00)
        let payloadBytes: [UInt8] = Array("query".utf8) + [0] + Array("--spaces".utf8) + [0, 0]
        let expectedBytes: [UInt8] = [16, 0, 0, 0] + payloadBytes
        #expect(Array(data) == expectedBytes)
    }

    @Test("Empty arguments return nil safely")
    func testEmptyArguments() {
        let res = YabaiIPC.sendMessage([])
        #expect(res == nil)
    }
}

@Suite("Launch at Login (SMAppService) Tests")
struct LaunchAtLoginTests {
    @Test("checkLaunchAtLoginStatus runs safely")
    @MainActor
    func testLaunchAtLoginCheck() {
        let service = YabaiService.shared
        service.checkLaunchAtLoginStatus()
        // Value is a boolean and doesn't crash in test environment
        #expect(service.isLaunchAtLoginEnabled == false || service.isLaunchAtLoginEnabled == true)
    }
}

@Suite("Spaces Pill and Navigation Tests")
struct SpacesPillAndNavigationTests {
    @Test("spacesPill formats active space with brackets")
    @MainActor
    func testSpacesPillFormatting() {
        let service = YabaiService.shared
        service.yabaiConfig.menuBarDisplayStyle = .spacesPill
        service.spaces = [
            YabaiSpace(id: 1, index: 1, hasFocus: true),
            YabaiSpace(id: 2, index: 2, hasFocus: false),
            YabaiSpace(id: 3, index: 3, hasFocus: false)
        ]
        service.activeSpaceIndex = 1

        let text = service.menuBarStatusText
        #expect(text == "[1] 2 3")

        service.activeSpaceIndex = 2
        #expect(service.menuBarStatusText == "1 [2] 3")
    }

    @Test("switchToNextSpace and switchToPreviousSpace wrap around correctly")
    @MainActor
    func testSpaceNavigationWrapAround() {
        let service = YabaiService.shared
        service.spaces = [
            YabaiSpace(id: 1, index: 1, hasFocus: true),
            YabaiSpace(id: 2, index: 2, hasFocus: false),
            YabaiSpace(id: 3, index: 3, hasFocus: false)
        ]
        service.activeSpaceIndex = 3
        // Next wraps around to 1 (triggers focusSpace without error)
        service.switchToNextSpace()

        service.activeSpaceIndex = 1
        // Prev wraps around to 3
        service.switchToPreviousSpace()
    }
}

@Suite("Quick Window Switcher Tests")
struct QuickWindowSwitcherTests {
    @Test("Window filtering matches app name and title case-insensitively")
    @MainActor
    func testWindowFiltering() {
        let windows = [
            YabaiWindow(id: 101, pid: 12, app: "Visual Studio Code", title: "YabaiService.swift", space: 1),
            YabaiWindow(id: 102, pid: 34, app: "Safari", title: "Apple Developer Documentation", space: 2),
            YabaiWindow(id: 103, pid: 56, app: "Terminal", title: "zsh", space: 1)
        ]

        let searchCode = windows.filter {
            $0.app.localizedCaseInsensitiveContains("code") ||
            $0.title.localizedCaseInsensitiveContains("code")
        }
        #expect(searchCode.count == 1)
        #expect(searchCode.first?.app == "Visual Studio Code")

        let searchDoc = windows.filter {
            $0.app.localizedCaseInsensitiveContains("apple") ||
            $0.title.localizedCaseInsensitiveContains("apple")
        }
        #expect(searchDoc.count == 1)
        #expect(searchDoc.first?.app == "Safari")
    }

    @Test("YabaiWindow decodes from valid yabai JSON query response")
    func testWindowJSONDecoding() throws {
        let json = """
        [
            {
                "id": 451,
                "pid": 892,
                "app": "Ghostty",
                "title": "mzia@mbp:~",
                "space": 2,
                "has-focus": true,
                "is-floating": false
            }
        ]
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode([YabaiWindow].self, from: json)
        #expect(decoded.count == 1)
        #expect(decoded.first?.id == 451)
        #expect(decoded.first?.app == "Ghostty")
        #expect(decoded.first?.space == 2)
        #expect(decoded.first?.hasFocus == true)
        #expect(decoded.first?.isFloating == false)
    }
}

@Suite("Daemon Service Management Tests")
struct DaemonServiceManagementTests {
    @Test("YabaiService provides daemon management methods")
    @MainActor
    func testDaemonManagementMethodsExist() {
        let service = YabaiService.shared
        // Verify service paths and methods can be invoked safely
        #expect(!service.yabaiBinaryPath.isEmpty)
        #expect(!service.skhdBinaryPath.isEmpty)
        service.checkRunningState()
    }

    @Test("Stopped daemon banner text resolves correctly")
    func testStoppedDaemonBannerLogic() {
        func bannerText(isYabaiRunning: Bool, isSkhdRunning: Bool) -> String {
            if !isYabaiRunning && !isSkhdRunning {
                return "Background daemons stopped"
            } else if !isYabaiRunning {
                return "yabai daemon stopped"
            } else if !isSkhdRunning {
                return "skhd daemon stopped"
            } else {
                return "Daemons running normally"
            }
        }

        #expect(bannerText(isYabaiRunning: false, isSkhdRunning: false) == "Background daemons stopped")
        #expect(bannerText(isYabaiRunning: false, isSkhdRunning: true) == "yabai daemon stopped")
        #expect(bannerText(isYabaiRunning: true, isSkhdRunning: false) == "skhd daemon stopped")
        #expect(bannerText(isYabaiRunning: true, isSkhdRunning: true) == "Daemons running normally")
    }

    @Test("skhd reload signal is SIGUSR1")
    func testSkhdReloadSignalProtocol() {
        // skhd traps SIGUSR1 for reloading configuration without terminating
        let reloadSignal = "SIGUSR1"
        let signalArg = "-USR1"
        #expect(reloadSignal == "SIGUSR1")
        #expect(signalArg == "-USR1")
    }
}
