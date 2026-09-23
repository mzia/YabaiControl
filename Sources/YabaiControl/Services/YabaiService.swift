import Foundation
import Combine
import ApplicationServices
import AppKit
import UniformTypeIdentifiers
import Darwin
import ServiceManagement

@MainActor
public class YabaiService: ObservableObject {
    public static let shared = YabaiService()

    @Published public var yabaiConfig = YabaiConfig()
    @Published public var skhdConfig = SKHDConfig()

    @Published public var isYabaiRunning: Bool = false
    @Published public var isSkhdRunning: Bool = false
    @Published public var isYabaiInstalled: Bool = false
    @Published public var isSkhdInstalled: Bool = false
    @Published public var isYabaiBundled: Bool = false
    @Published public var isSkhdBundled: Bool = false
    @Published public var hasAccessibilityPermission: Bool = false
    @Published public var statusMessage: String = "Ready"

    // Workspaces & Spaces
    @Published public var spaces: [YabaiSpace] = []
    @Published public var activeSpaceIndex: Int = 1

    // Windows & Quick Switcher
    @Published public var allWindows: [YabaiWindow] = []

    // Launch at Login
    @Published public var isLaunchAtLoginEnabled: Bool = false
    @Published public var launchAtLoginStatusMessage: String = ""

    // Workflow Profiles
    @Published public var activeProfileId: String? = "balanced"

    // Scripting Addition & SIP
    @Published public var isSALoaded: Bool = false
    @Published public var sipStatusText: String = "Checking..."
    @Published public var sudoersCommand: String = ""

    // Update & Restart Management
    @Published public var isUpdateAvailable: Bool = false
    @Published public var isRestartRequired: Bool = false
    @Published public var updateVersion: String = ""
    @Published public var updateReleaseNotes: String = ""
    @Published public var lastUpdateCheckDate: Date? = nil
    @Published public var isCheckingForUpdates: Bool = false
    @Published public var updateStatusMessage: String = "Up to date"

    public var isUpdatePendingRestart: Bool {
        isUpdateAvailable && isRestartRequired
    }

    // UI state
    @Published public var selectedTab: Int = 0
    @Published public var newAppName: String = ""
    @Published public var windowSearchText: String = ""
    @Published public var showUninstallAlert: Bool = false

    public var menuBarIcon: String {
        yabaiConfig.layout.iconName
    }

    public var menuBarStatusText: String {
        switch yabaiConfig.menuBarDisplayStyle {
        case .iconOnly:
            return ""
        case .iconAndLayout:
            return yabaiConfig.layout.rawValue.uppercased()
        case .iconAndSpace:
            return "S\(activeSpaceIndex)"
        case .iconAndBoth:
            return "\(yabaiConfig.layout.rawValue.uppercased()) • S\(activeSpaceIndex)"
        case .spacesPill:
            if spaces.isEmpty {
                return "S\(activeSpaceIndex)"
            }
            return spaces.sorted(by: { $0.index < $1.index }).map { s in
                s.index == activeSpaceIndex ? "[\(s.index)]" : "\(s.index)"
            }.joined(separator: " ")
        }
    }

    nonisolated(unsafe) private var timer: Timer?

    private var homeDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
    }

    public var yabaircURL: URL {
        homeDir.appendingPathComponent(".yabairc")
    }

    public var skhdrcURL: URL {
        homeDir.appendingPathComponent(".skhdrc")
    }

    // Resolves yabai binary path (prioritizes stable system/homebrew paths for persistent TCC permissions)
    public var yabaiBinaryPath: String {
        for path in ["/opt/homebrew/bin/yabai", "/usr/local/bin/yabai", "\(homeDir.path)/.local/bin/yabai"] {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        if let bundlePath = Bundle.main.path(forResource: "yabai", ofType: nil, inDirectory: "bin"),
           FileManager.default.fileExists(atPath: bundlePath) {
            return bundlePath
        }
        return "/opt/homebrew/bin/yabai"
    }

    // Resolves skhd binary path
    public var skhdBinaryPath: String {
        for path in ["/opt/homebrew/bin/skhd", "/usr/local/bin/skhd", "\(homeDir.path)/.local/bin/skhd"] {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        if let bundlePath = Bundle.main.path(forResource: "skhd", ofType: nil, inDirectory: "bin"),
           FileManager.default.fileExists(atPath: bundlePath) {
            return bundlePath
        }
        return "/opt/homebrew/bin/skhd"
    }

    nonisolated(unsafe) private var workspaceObservers: [NSObjectProtocol] = []

    private init() {
        checkInstallations()
        checkRunningState()
        checkAccessibility()
        loadConfigs()
        querySpaces()
        checkScriptingAddition()
        setupEventObservers()

        // Low-power background heartbeat with timer coalescing (App Nap friendly)
        let heartbeat = Timer(timeInterval: 20.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkRunningState()
                self?.checkTrashStatus()
            }
        }
        heartbeat.tolerance = 5.0
        RunLoop.main.add(heartbeat, forMode: .common)
        self.timer = heartbeat
    }

    private func setupEventObservers() {
        let center = NSWorkspace.shared.notificationCenter

        // 1. Instant space change notification via macOS WindowServer (0ms latency, zero polling)
        let spaceObs = center.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.querySpaces()
            }
        }
        workspaceObservers.append(spaceObs)

        // 2. Instant process launch/termination notifications
        let launchObs = center.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkRunningState()
            }
        }
        workspaceObservers.append(launchObs)

        let termObs = center.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkRunningState()
            }
        }
        workspaceObservers.append(termObs)

        // 3. Screen parameters changed (multi-monitor plug/unplug)
        let screenObs = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.querySpaces()
            }
        }
        workspaceObservers.append(screenObs)

        // 4. App became active (user opened popover or settings)
        let activeObs = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshAllState()
            }
        }
        workspaceObservers.append(activeObs)
    }

    public func refreshAllState() {
        checkInstallations()
        checkRunningState()
        checkAccessibility()
        querySpaces()
        queryWindows()
        checkLaunchAtLoginStatus()
        checkTrashStatus()
    }

    public func checkInstallations() {
        isYabaiInstalled = FileManager.default.fileExists(atPath: yabaiBinaryPath)
        isSkhdInstalled = FileManager.default.fileExists(atPath: skhdBinaryPath)
        isYabaiBundled = yabaiBinaryPath.contains("Resources/bin") || yabaiBinaryPath.contains(".app")
        isSkhdBundled = skhdBinaryPath.contains("Resources/bin") || skhdBinaryPath.contains(".app")
    }

    public func checkAccessibility() {
        // 1. Check user acknowledgment in UserDefaults
        if UserDefaults.standard.bool(forKey: "hasAccessibilityPermissionAcknowledged") {
            hasAccessibilityPermission = true
            return
        }

        // 2. Standard macOS Accessibility API
        if AXIsProcessTrusted() {
            hasAccessibilityPermission = true
            return
        }

        // 3. Test macOS Accessibility Subsystem via System Events probe
        let sysEventsCheck = runCommand("/usr/bin/osascript", args: ["-e", "tell application \"System Events\" to return true"])
        if sysEventsCheck.status == 0 && sysEventsCheck.output.trimmingCharacters(in: .whitespacesAndNewlines) == "true" {
            hasAccessibilityPermission = true
            return
        }

        // 4. Check if yabai is running and responding to space queries
        if isYabaiInstalled && isYabaiRunning {
            let res = runYabaiCommand(["query", "--spaces"])
            if res.status == 0 && !res.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                hasAccessibilityPermission = true
                return
            }
        }

        hasAccessibilityPermission = false
    }

    public func acknowledgeAccessibilityPermission() {
        UserDefaults.standard.set(true, forKey: "hasAccessibilityPermissionAcknowledged")
        hasAccessibilityPermission = true
        statusMessage = "Accessibility permission confirmed."
    }

    public func resetAccessibilityPermissionCheck() {
        UserDefaults.standard.removeObject(forKey: "hasAccessibilityPermissionAcknowledged")
        checkAccessibility()
    }

    public func checkRunningState() {
        isYabaiRunning = isProcessRunning("yabai")
        isSkhdRunning = isProcessRunning("skhd")
    }

    public func isProcessRunning(_ name: String) -> Bool {
        // 1. In-memory check for running applications via NSWorkspace (0 subprocess forks)
        let runningApps = NSWorkspace.shared.runningApplications
        if runningApps.contains(where: {
            $0.localizedName?.lowercased() == name.lowercased() ||
            $0.executableURL?.lastPathComponent.lowercased() == name.lowercased()
        }) {
            return true
        }

        // 2. In-memory check for BSD background daemons via Darwin libproc (0 subprocess forks)
        var pids = [pid_t](repeating: 0, count: 2048)
        let bytesUsed = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, Int32(MemoryLayout<pid_t>.size * pids.count))
        guard bytesUsed > 0 else { return false }

        let count = Int(bytesUsed) / MemoryLayout<pid_t>.size
        var nameBuffer = [CChar](repeating: 0, count: 256)
        for i in 0..<count where pids[i] > 0 {
            let length = proc_name(pids[i], &nameBuffer, UInt32(nameBuffer.count))
            if length > 0 {
                let procName = nameBuffer.withUnsafeBufferPointer { ptr in
                    ptr.baseAddress.map { String(cString: $0) } ?? ""
                }
                if procName == name {
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Config Persistence

    public func loadConfigs() {
        if FileManager.default.fileExists(atPath: yabaircURL.path) {
            if let content = try? String(contentsOf: yabaircURL, encoding: .utf8) {
                parseYabairc(content)
            }
        }

        if FileManager.default.fileExists(atPath: skhdrcURL.path) {
            if let content = try? String(contentsOf: skhdrcURL, encoding: .utf8) {
                parseSkhdrc(content)
            }
        }
    }

    private func parseYabairc(_ content: String) {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") || trimmed.isEmpty { continue }

            if trimmed.contains("config layout") {
                if trimmed.contains("bsp") { yabaiConfig.layout = .bsp }
                else if trimmed.contains("stack") { yabaiConfig.layout = .stack }
                else if trimmed.contains("float") { yabaiConfig.layout = .float }
            } else if trimmed.contains("config window_gap") {
                if let val = trimmed.components(separatedBy: " ").last, let intVal = Int(val) {
                    yabaiConfig.windowGap = intVal
                }
            } else if trimmed.contains("config top_padding") {
                if let val = trimmed.components(separatedBy: " ").last, let intVal = Int(val) {
                    yabaiConfig.topPadding = intVal
                }
            } else if trimmed.contains("config bottom_padding") {
                if let val = trimmed.components(separatedBy: " ").last, let intVal = Int(val) {
                    yabaiConfig.bottomPadding = intVal
                }
            } else if trimmed.contains("config focus_follows_mouse") {
                if trimmed.contains("autoraise") { yabaiConfig.focusFollowsMouse = .autoraise }
                else if trimmed.contains("autofocus") { yabaiConfig.focusFollowsMouse = .autofocus }
                else { yabaiConfig.focusFollowsMouse = .off }
            } else if trimmed.contains("config mouse_follows_focus") {
                yabaiConfig.mouseFollowsFocus = trimmed.contains("on")
            }
        }
    }

    private func parseSkhdrc(_ content: String) {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("window --focus west") {
                if let key = trimmed.components(separatedBy: ":").first?.components(separatedBy: "-").last?.trimmingCharacters(in: .whitespaces) {
                    skhdConfig.focusLeft = key
                }
            }
        }
    }

    public func saveAndApply() {
        let yabaiContent = yabaiConfig.generateYabairc()
        let skhdContent = skhdConfig.generateSkhdrc()

        do {
            try yabaiContent.write(to: yabaircURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: yabaircURL.path)

            try skhdContent.write(to: skhdrcURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: skhdrcURL.path)

            statusMessage = "Configuration saved!"
            applyLiveSettings()
        } catch {
            statusMessage = "Error saving config: \(error.localizedDescription)"
        }
    }

    public func applyLiveSettings() {
        guard isYabaiRunning else { return }
        runYabaiCommand(["config", "layout", yabaiConfig.layout.rawValue])
        runYabaiCommand(["config", "window_gap", "\(yabaiConfig.windowGap)"])
        runYabaiCommand(["config", "top_padding", "\(yabaiConfig.topPadding)"])
        runYabaiCommand(["config", "bottom_padding", "\(yabaiConfig.bottomPadding)"])
        runYabaiCommand(["config", "left_padding", "\(yabaiConfig.leftPadding)"])
        runYabaiCommand(["config", "right_padding", "\(yabaiConfig.rightPadding)"])
        runYabaiCommand(["config", "focus_follows_mouse", yabaiConfig.focusFollowsMouse.rawValue])
        runYabaiCommand(["config", "mouse_follows_focus", yabaiConfig.mouseFollowsFocus ? "on" : "off"])

        if isSkhdRunning {
            runCommand("/usr/bin/killall", args: ["-HUP", "skhd"])
        }
    }

    // MARK: - Service Control

    public func startServices() {
        // 1. Ensure config files exist
        if !FileManager.default.fileExists(atPath: yabaircURL.path) ||
           !FileManager.default.fileExists(atPath: skhdrcURL.path) {
            saveAndApply()
        }

        // 2. Start yabai service via launchd
        if isYabaiInstalled {
            runCommand(yabaiBinaryPath, args: ["--start-service"])
        }

        // 3. Start skhd service via launchd
        if isSkhdInstalled {
            runCommand(skhdBinaryPath, args: ["--start-service"])
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.checkRunningState()
            if self.isYabaiRunning && self.isSkhdRunning {
                self.statusMessage = "Daemons running normally."
            } else {
                self.statusMessage = "Permission Required: Please allow yabai & skhd in System Settings."
            }
        }
    }

    public func stopServices() {
        if isYabaiInstalled {
            runCommand(yabaiBinaryPath, args: ["--stop-service"])
        }
        if isSkhdInstalled {
            runCommand(skhdBinaryPath, args: ["--stop-service"])
        }

        runCommand("/usr/bin/pkill", args: ["-x", "yabai"])
        runCommand("/usr/bin/pkill", args: ["-x", "skhd"])

        statusMessage = "Services stopped."

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkRunningState()
        }
    }

    public func restartServices() {
        stopServices()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startServices()
        }
    }

    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    public func openInputMonitoringSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }

    public func setLayout(_ layout: YabaiLayout) {
        yabaiConfig.layout = layout
        applyLiveSettings()
    }

    public func balanceSizes() {
        runYabaiCommand(["space", "--balance"])
    }

    public func toggleActiveWindowFloat() {
        runYabaiCommand(["window", "--toggle", "float", "--grid", "4:4:1:1:2:2"])
    }

    // MARK: - Workspaces & Spaces

    public func querySpaces() {
        guard isYabaiRunning else { return }
        let res = runYabaiCommand(["query", "--spaces"])
        guard res.status == 0, let data = res.output.data(using: .utf8) else { return }
        if let decoded = try? JSONDecoder().decode([YabaiSpace].self, from: data) {
            self.spaces = decoded
            if let focused = decoded.first(where: { $0.hasFocus }) {
                self.activeSpaceIndex = focused.index
            }
        }
    }

    public func focusSpace(index: Int) {
        runYabaiCommand(["space", "--focus", "\(index)"])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.querySpaces()
            self.queryWindows()
        }
    }

    public func switchToNextSpace() {
        guard !spaces.isEmpty else { return }
        let sorted = spaces.sorted(by: { $0.index < $1.index })
        if let currentIdx = sorted.firstIndex(where: { $0.index == activeSpaceIndex }) {
            let nextIdx = (currentIdx + 1) % sorted.count
            focusSpace(index: sorted[nextIdx].index)
        } else if let first = sorted.first {
            focusSpace(index: first.index)
        }
    }

    public func switchToPreviousSpace() {
        guard !spaces.isEmpty else { return }
        let sorted = spaces.sorted(by: { $0.index < $1.index })
        if let currentIdx = sorted.firstIndex(where: { $0.index == activeSpaceIndex }) {
            let prevIdx = (currentIdx - 1 + sorted.count) % sorted.count
            focusSpace(index: sorted[prevIdx].index)
        } else if let last = sorted.last {
            focusSpace(index: last.index)
        }
    }

    // MARK: - Windows & Quick Switcher

    public func queryWindows() {
        guard isYabaiRunning else { return }
        let res = runYabaiCommand(["query", "--windows"])
        guard res.status == 0, let data = res.output.data(using: .utf8) else { return }
        if let decoded = try? JSONDecoder().decode([YabaiWindow].self, from: data) {
            self.allWindows = decoded.filter { !$0.app.isEmpty }
        }
    }

    public func focusWindow(id: Int, space: Int = 1) {
        runYabaiCommand(["window", "--focus", "\(id)"])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.querySpaces()
            self.queryWindows()
        }
    }

    // MARK: - Visual Quick-Snap Grid

    public func snapActiveWindow(to position: WindowSnapPosition) {
        runYabaiCommand(["window", "--grid", position.gridCommand])
        statusMessage = "Snapped window to \(position.rawValue)."
    }

    // MARK: - Launch at Login (SMAppService)

    public func checkLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            isLaunchAtLoginEnabled = (SMAppService.mainApp.status == .enabled)
        }
    }

    public func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    statusMessage = "YabaiControl registered to launch at login."
                } else {
                    try SMAppService.mainApp.unregister()
                    statusMessage = "YabaiControl removed from login items."
                }
                isLaunchAtLoginEnabled = (SMAppService.mainApp.status == .enabled)
                launchAtLoginStatusMessage = enabled ? "Registered as Login Item" : "Not Registered"
            } catch {
                launchAtLoginStatusMessage = "Error: \(error.localizedDescription)"
                isLaunchAtLoginEnabled = (SMAppService.mainApp.status == .enabled)
            }
        }
    }

    // MARK: - Workflow Profiles & Presets

    public func applyProfile(_ profile: WindowProfile) {
        activeProfileId = profile.id
        yabaiConfig.layout = profile.layout
        yabaiConfig.windowGap = profile.windowGap
        yabaiConfig.topPadding = profile.padding
        yabaiConfig.bottomPadding = profile.padding
        yabaiConfig.leftPadding = profile.padding
        yabaiConfig.rightPadding = profile.padding
        yabaiConfig.splitRatio = profile.splitRatio
        yabaiConfig.focusFollowsMouse = profile.focusFollowsMouse
        yabaiConfig.windowOpacity = profile.windowOpacity
        yabaiConfig.activeOpacity = profile.activeOpacity

        applyLiveSettings()
        saveAndApply()
        statusMessage = "Applied '\(profile.name)' profile."
    }

    // MARK: - Scripting Addition (SA) & SIP

    public func checkScriptingAddition() {
        let sipRes = runCommand("/usr/bin/csrutil", args: ["status"])
        if sipRes.status == 0 {
            sipStatusText = sipRes.output.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            sipStatusText = "Unknown"
        }

        let whoami = NSUserName()
        let shasumRes = runCommand("/usr/bin/shasum", args: ["-a", "256", yabaiBinaryPath])
        let hash = shasumRes.output.components(separatedBy: " ").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "<sha256>"
        sudoersCommand = "\(whoami) ALL=(root) NOPASSWD: sha256:\(hash) \(yabaiBinaryPath) --load-sa"
    }

    public func loadScriptingAddition() {
        let res = runCommand("/usr/bin/sudo", args: [yabaiBinaryPath, "--load-sa"])
        if res.status == 0 {
            isSALoaded = true
            statusMessage = "Scripting Addition loaded successfully."
        } else {
            statusMessage = "Could not load SA (requires sudoers entry or SIP partial disablement)."
        }
    }

    public func installCLIToolsToUserPath() {
        let userLocalBin = homeDir.appendingPathComponent(".local/bin")
        try? FileManager.default.createDirectory(at: userLocalBin, withIntermediateDirectories: true)
        let yabaiDest = userLocalBin.appendingPathComponent("yabai").path
        let skhdDest = userLocalBin.appendingPathComponent("skhd").path
        try? FileManager.default.removeItem(atPath: yabaiDest)
        try? FileManager.default.removeItem(atPath: skhdDest)
        try? FileManager.default.createSymbolicLink(atPath: yabaiDest, withDestinationPath: yabaiBinaryPath)
        try? FileManager.default.createSymbolicLink(atPath: skhdDest, withDestinationPath: skhdBinaryPath)
        statusMessage = "CLI tools symlinked into ~/.local/bin"
    }

    // MARK: - Update & Restart Management

    public func setUpdatePendingRestart(available: Bool, restartRequired: Bool, version: String = "") {
        self.isUpdateAvailable = available
        self.isRestartRequired = restartRequired
        if !version.isEmpty {
            self.updateVersion = version
            self.updateStatusMessage = "Version \(version) ready. Restart required."
        }
    }

    public func toggleSimulatedUpdate() {
        if isUpdatePendingRestart {
            isUpdateAvailable = false
            isRestartRequired = false
            updateVersion = ""
            statusMessage = "Update status cleared."
            updateStatusMessage = "Up to date"
        } else {
            isUpdateAvailable = true
            isRestartRequired = true
            updateVersion = "1.1.0"
            statusMessage = "Simulated update ready. Restart required."
            updateStatusMessage = "Version 1.1.0 ready. Restart required."
        }
    }

    public func performPendingRestart() {
        isRestartRequired = false
        isUpdateAvailable = false
        statusMessage = "Restarting services and applying updates..."
        restartServices()
    }

    public func checkForUpdates() {
        guard !isCheckingForUpdates else { return }
        isCheckingForUpdates = true
        updateStatusMessage = "Checking for updates..."

        guard let url = URL(string: "https://api.github.com/repos/mzia/YabaiControl/releases/latest") else {
            isCheckingForUpdates = false
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("YabaiControl-App", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isCheckingForUpdates = false
                self.lastUpdateCheckDate = Date()

                if let error = error {
                    self.updateStatusMessage = "Check failed: \(error.localizedDescription)"
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String else {
                    self.updateStatusMessage = "YabaiControl is up to date."
                    return
                }

                let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                let cleanTag = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))

                if self.isVersion(cleanTag, greaterThan: currentVersion) {
                    self.isUpdateAvailable = true
                    self.isRestartRequired = true
                    self.updateVersion = cleanTag
                    self.updateReleaseNotes = (json["body"] as? String) ?? ""
                    self.updateStatusMessage = "Version \(cleanTag) ready. Restart required."
                    self.statusMessage = "Update \(cleanTag) available. Restart required."
                } else {
                    self.isUpdateAvailable = false
                    self.updateStatusMessage = "YabaiControl \(currentVersion) is up to date."
                }
            }
        }.resume()
    }

    public func isVersion(_ v1: String, greaterThan v2: String) -> Bool {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }
        let maxCount = max(parts1.count, parts2.count)
        for i in 0..<maxCount {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0
            if p1 > p2 { return true }
            if p1 < p2 { return false }
        }
        return false
    }

    // MARK: - Floating Application Management

    public func addFloatingApp(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !yabaiConfig.floatingApps.contains(trimmed) {
            yabaiConfig.floatingApps.append(trimmed)
            statusMessage = "Added '\(trimmed)' to floating rules."
        }
    }

    public func removeFloatingApp(_ name: String) {
        yabaiConfig.floatingApps.removeAll { $0 == name }
        statusMessage = "Removed '\(name)' from floating rules."
    }

    public func selectAppFromFinder() {
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSOpenPanel()
        panel.title = "Select Application to Float"
        panel.message = "Choose an application that should float freely instead of autotiling."
        panel.prompt = "Add to Rules"
        panel.allowedContentTypes = [UTType.application, UTType.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.treatsFilePackagesAsDirectories = false

        let response = panel.runModal()
        if response == .OK {
            var addedCount = 0
            for url in panel.urls {
                let name = resolveAppName(from: url)
                if !name.isEmpty && !yabaiConfig.floatingApps.contains(name) {
                    yabaiConfig.floatingApps.append(name)
                    addedCount += 1
                }
            }
            if addedCount > 0 {
                statusMessage = "Added \(addedCount) application\(addedCount > 1 ? "s" : "") to floating rules."
            }
        }
    }

    public func resolveAppName(from url: URL) -> String {
        if let bundle = Bundle(url: url) {
            if let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, !displayName.isEmpty {
                return displayName
            }
            if let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String, !name.isEmpty {
                return name
            }
        }
        return url.deletingPathExtension().lastPathComponent
    }

    public func appIcon(for appName: String) -> NSImage? {
        let searchDirectories = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            "\(homeDir.path)/Applications"
        ]

        for dir in searchDirectories {
            let path = "\(dir)/\(appName).app"
            if FileManager.default.fileExists(atPath: path) {
                return NSWorkspace.shared.icon(forFile: path)
            }
        }

        // Check if bundle identifier lookup works
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appName) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }

        return nil
    }

    public func checkTrashStatus() {
        let bundlePath = Bundle.main.bundleURL.path
        // If app bundle has been moved to ~/.Trash
        if bundlePath.contains("/.Trash/") {
            cleanupAllServices(deleteConfigs: false)
            NSApplication.shared.terminate(nil)
        }
    }

    public func cleanupAllServices(deleteConfigs: Bool = false) {
        stopServices()

        let launchAgents = homeDir.appendingPathComponent("Library/LaunchAgents")
        let yabaiPlist = launchAgents.appendingPathComponent("com.asmvik.yabai.plist")
        let skhdPlist = launchAgents.appendingPathComponent("com.koekeishiya.skhd.plist")

        if FileManager.default.fileExists(atPath: yabaiPlist.path) {
            runCommand("/bin/launchctl", args: ["bootout", "gui/\(getuid())", yabaiPlist.path])
            try? FileManager.default.removeItem(at: yabaiPlist)
        }
        if FileManager.default.fileExists(atPath: skhdPlist.path) {
            runCommand("/bin/launchctl", args: ["bootout", "gui/\(getuid())", skhdPlist.path])
            try? FileManager.default.removeItem(at: skhdPlist)
        }

        let userLocalBin = homeDir.appendingPathComponent(".local/bin")
        try? FileManager.default.removeItem(at: userLocalBin.appendingPathComponent("yabai"))
        try? FileManager.default.removeItem(at: userLocalBin.appendingPathComponent("skhd"))

        if deleteConfigs {
            try? FileManager.default.removeItem(at: yabaircURL)
            try? FileManager.default.removeItem(at: skhdrcURL)
        }
    }

    public func uninstallApp() {
        cleanupAllServices(deleteConfigs: false)
        NSWorkspace.shared.recycle([Bundle.main.bundleURL]) { _, _ in
            DispatchQueue.main.async {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    @discardableResult
    public func runYabaiCommand(_ arguments: [String]) -> (status: Int32, output: String) {
        var cleanArgs = arguments
        if cleanArgs.first == "-m" {
            cleanArgs.removeFirst()
        }

        // 1. Zero-fork UNIX Domain Socket IPC (<0.2ms round-trip, zero Mach tasks)
        if let socketResponse = YabaiIPC.sendMessage(cleanArgs) {
            return socketResponse
        }

        // 2. Fall back to standard Process() subprocess CLI if socket offline
        let fullArgs = cleanArgs.first == "-m" ? cleanArgs : (["-m"] + cleanArgs)
        return runCommand(yabaiBinaryPath, args: fullArgs)
    }

    @discardableResult
    private func runCommand(_ binary: String, args: [String]) -> (status: Int32, output: String) {
        guard FileManager.default.fileExists(atPath: binary) else { return (-1, "Not found") }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: binary)
        process.arguments = args

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let out = String(data: data, encoding: .utf8) ?? ""
            return (process.terminationStatus, out)
        } catch {
            return (-1, error.localizedDescription)
        }
    }

    deinit {
        timer?.invalidate()
        for obs in workspaceObservers {
            NotificationCenter.default.removeObserver(obs)
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
    }
}
