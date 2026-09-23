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
    }

    @Test("generateSkhdrc produces expected shortcut bindings")
    func testGenerateSkhdrc() {
        var config = SKHDConfig()
        config.primaryModifier = "cmd + alt"

        let script = config.generateSkhdrc()

        #expect(script.contains("cmd + alt - h : yabai -m window --focus west"))
        #expect(script.contains("cmd + alt - j : yabai -m window --focus south"))
        #expect(script.contains("cmd + alt - k : yabai -m window --focus north"))
        #expect(script.contains("cmd + alt - l : yabai -m window --focus east"))
        #expect(script.contains("shift + cmd + alt - h : yabai -m window --swap west"))
        #expect(script.contains("cmd + alt - t : yabai -m window --toggle float --grid 4:4:1:1:2:2"))
        #expect(script.contains("cmd + alt - e : yabai -m window --toggle split"))
        #expect(script.contains("cmd + alt - b : yabai -m space --balance"))
        #expect(script.contains("shift + cmd + alt - r : yabai --restart-service"))
        #expect(script.contains("cmd + alt - 1 : yabai -m space --focus 1"))
        #expect(script.contains("shift + cmd + alt - 5 : yabai -m window --space 5"))
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
