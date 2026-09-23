import Testing
import Foundation
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
