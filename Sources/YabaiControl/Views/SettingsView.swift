import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject private var service: YabaiService

    public init() {}

    public var body: some View {
        TabView(selection: $service.selectedTab) {
            layoutTabView
                .tabItem { Label("Layout", systemImage: "rectangle.split.2x2") }
                .tag(0)

            gapsTabView
                .tabItem { Label("Gaps & Margins", systemImage: "arrow.up.and.down.and.arrow.left.and.right") }
                .tag(1)

            rulesTabView
                .tabItem { Label("Floating Apps", systemImage: "macwindow.on.rectangle") }
                .tag(2)

            shortcutsTabView
                .tabItem { Label("Keybindings", systemImage: "keyboard") }
                .tag(3)

            profilesTabView
                .tabItem { Label("Profiles", systemImage: "sparkles.rectangle.stack") }
                .tag(5)

            servicesTabView
                .tabItem { Label("Services", systemImage: "gearshape.2") }
                .tag(4)
        }
        .padding(20)
        .frame(minWidth: 620, minHeight: 480)
        .confirmationDialog(
            "Uninstall YabaiControl?",
            isPresented: $service.showUninstallAlert,
            titleVisibility: .visible
        ) {
            Button("Uninstall & Trash App", role: .destructive) {
                service.uninstallApp()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will stop all running daemons, remove launch agents and CLI symlinks, and move YabaiControl to the Trash.")
        }
    }

    // MARK: - Tab 1: Layout & Behavior
    private var layoutTabView: some View {
        Form {
            Section(header: Text("Tiling Behavior").font(.headline)) {
                Picker("Layout Algorithm", selection: $service.yabaiConfig.layout) {
                    ForEach(YabaiLayout.allCases) { layout in
                        Text(layout.displayName).tag(layout)
                    }
                }
                .pickerStyle(.radioGroup)

                Toggle("Auto-Balance Window Sizes", isOn: $service.yabaiConfig.autoBalance)

                HStack {
                    Text("Default Split Ratio: \(Int(service.yabaiConfig.splitRatio * 100))%")
                    Slider(value: $service.yabaiConfig.splitRatio, in: 0.1...0.9, step: 0.05)
                }
            }

            Section(header: Text("Mouse Interaction").font(.headline)) {
                Picker("Focus Follows Mouse", selection: $service.yabaiConfig.focusFollowsMouse) {
                    ForEach(FocusFollowsMouseMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)

                Toggle("Warp Mouse to Center of Focused Window", isOn: $service.yabaiConfig.mouseFollowsFocus)
            }

            Section(header: Text("Menu Bar Title & Appearance").font(.headline)) {
                Picker("Display Format in Menu Bar", selection: $service.yabaiConfig.menuBarDisplayStyle) {
                    ForEach(MenuBarDisplayStyle.allCases) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section(header: Text("Startup & Login Item").font(.headline)) {
                Toggle("Launch YabaiControl at Login", isOn: Binding(
                    get: { service.isLaunchAtLoginEnabled },
                    set: { service.setLaunchAtLogin(enabled: $0) }
                ))
                Text("Automatically launches YabaiControl when you log into macOS using modern Service Management (SMAppService).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !service.launchAtLoginStatusMessage.isEmpty {
                    Text(service.launchAtLoginStatusMessage)
                        .font(.caption2)
                        .foregroundStyle(service.isLaunchAtLoginEnabled ? .green : .secondary)
                }
            }

            Spacer()

            saveButton
        }
    }

    // MARK: - Tab 2: Gaps & Padding
    private var gapsTabView: some View {
        Form {
            Section(header: Text("Window Spacing (Pixels)").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Window Gap: \(service.yabaiConfig.windowGap)px")
                            .frame(width: 150, alignment: .leading)
                        Slider(value: Binding(
                            get: { Double(service.yabaiConfig.windowGap) },
                            set: { service.yabaiConfig.windowGap = Int($0) }
                        ), in: 0...40, step: 1)
                    }

                    HStack {
                        Text("Top Margin: \(service.yabaiConfig.topPadding)px")
                            .frame(width: 150, alignment: .leading)
                        Slider(value: Binding(
                            get: { Double(service.yabaiConfig.topPadding) },
                            set: { service.yabaiConfig.topPadding = Int($0) }
                        ), in: 0...50, step: 1)
                    }

                    HStack {
                        Text("Bottom Margin: \(service.yabaiConfig.bottomPadding)px")
                            .frame(width: 150, alignment: .leading)
                        Slider(value: Binding(
                            get: { Double(service.yabaiConfig.bottomPadding) },
                            set: { service.yabaiConfig.bottomPadding = Int($0) }
                        ), in: 0...50, step: 1)
                    }

                    HStack {
                        Text("Side Margins: \(service.yabaiConfig.leftPadding)px")
                            .frame(width: 150, alignment: .leading)
                        Slider(value: Binding(
                            get: { Double(service.yabaiConfig.leftPadding) },
                            set: {
                                service.yabaiConfig.leftPadding = Int($0)
                                service.yabaiConfig.rightPadding = Int($0)
                            }
                        ), in: 0...50, step: 1)
                    }
                }
            }

            Section(header: Text("Window Opacity").font(.headline)) {
                Toggle("Enable Inactive Window Dimming", isOn: $service.yabaiConfig.windowOpacity)

                if service.yabaiConfig.windowOpacity {
                    HStack {
                        Text("Normal Opacity: \(Int(service.yabaiConfig.normalOpacity * 100))%")
                        Slider(value: $service.yabaiConfig.normalOpacity, in: 0.5...1.0, step: 0.05)
                    }
                }
            }

            Spacer()

            saveButton
        }
    }

    // MARK: - Tab 3: Floating Rules
    private var rulesTabView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Floating Applications")
                        .font(.headline)
                    Text("These apps will float freely instead of being partitioned into the tiling grid.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(service.yabaiConfig.floatingApps.count) Rules")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }

            // Primary action: Finder OpenPanel picker
            HStack(spacing: 10) {
                Button {
                    service.selectAppFromFinder()
                } label: {
                    Label("Select App from Finder...", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)

                Text("or enter manually:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("App name (e.g. Slack)", text: $service.newAppName)
                    .textFieldStyle(.roundedBorder)

                Button("Add") {
                    service.addFloatingApp(service.newAppName)
                    service.newAppName = ""
                }
                .disabled(service.newAppName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            List {
                ForEach(service.yabaiConfig.floatingApps, id: \.self) { app in
                    HStack(spacing: 8) {
                        if let icon = service.appIcon(for: app) {
                            Image(nsImage: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 18, height: 18)
                        } else {
                            Image(systemName: "app.dashed")
                                .frame(width: 18, height: 18)
                                .foregroundStyle(.secondary)
                        }

                        Text(app)
                            .font(.body)

                        Spacer()

                        Button(role: .destructive) {
                            service.removeFloatingApp(app)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))

            saveButton
        }
    }

    // MARK: - Tab 4: Shortcuts (skhd)
    private var shortcutsTabView: some View {
        Form {
            Section(header: Text("Keyboard Hotkeys (skhd)").font(.headline)) {
                HStack {
                    Text("Primary Modifier:")
                    Picker("", selection: $service.skhdConfig.primaryModifier) {
                        Text("Option / Alt (Recommended)").tag("alt")
                        Text("Command").tag("cmd")
                        Text("Control + Option").tag("ctrl + alt")
                    }
                    .pickerStyle(.menu)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("Presets:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Button("Vim") {
                            service.skhdConfig.focusLeft = "h"
                            service.skhdConfig.focusDown = "j"
                            service.skhdConfig.focusUp = "k"
                            service.skhdConfig.focusRight = "l"
                            service.skhdConfig.swapLeft = "h"
                            service.skhdConfig.swapDown = "j"
                            service.skhdConfig.swapUp = "k"
                            service.skhdConfig.swapRight = "l"
                        }
                        .controlSize(.mini)

                        Button("Arrows") {
                            service.skhdConfig.focusLeft = "left"
                            service.skhdConfig.focusDown = "down"
                            service.skhdConfig.focusUp = "up"
                            service.skhdConfig.focusRight = "right"
                            service.skhdConfig.swapLeft = "left"
                            service.skhdConfig.swapDown = "down"
                            service.skhdConfig.swapUp = "up"
                            service.skhdConfig.swapRight = "right"
                        }
                        .controlSize(.mini)

                        Button("WASD") {
                            service.skhdConfig.focusLeft = "a"
                            service.skhdConfig.focusDown = "s"
                            service.skhdConfig.focusUp = "w"
                            service.skhdConfig.focusRight = "d"
                            service.skhdConfig.swapLeft = "a"
                            service.skhdConfig.swapDown = "s"
                            service.skhdConfig.swapUp = "w"
                            service.skhdConfig.swapRight = "d"
                        }
                        .controlSize(.mini)
                    }
                }

                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                    GridRow {
                        Text("Focus West:").fontWeight(.medium)
                        TextField("", text: $service.skhdConfig.focusLeft).frame(width: 50)

                        Text("Focus South:").fontWeight(.medium)
                        TextField("", text: $service.skhdConfig.focusDown).frame(width: 50)
                    }
                    GridRow {
                        Text("Focus North:").fontWeight(.medium)
                        TextField("", text: $service.skhdConfig.focusUp).frame(width: 50)

                        Text("Focus East:").fontWeight(.medium)
                        TextField("", text: $service.skhdConfig.focusRight).frame(width: 50)
                    }
                    GridRow {
                        Text("Toggle Float:").fontWeight(.medium)
                        TextField("", text: $service.skhdConfig.toggleFloat).frame(width: 50)

                        Text("Balance Sizes:").fontWeight(.medium)
                        TextField("", text: $service.skhdConfig.balanceSizes).frame(width: 50)
                    }
                }
            }

            Text("Tip: Window swap/move shortcuts automatically map to [ Shift + Modifier + Key ].")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            saveButton
        }
    }

    // MARK: - Tab 4: Workflow Profiles
    private var profilesTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Workflow Profiles")
                    .font(.headline)
                Text("Instantly switch window layouts, padding, gap sizes, and mouse focus behaviors tailored for different workflows.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(WindowProfile.presets) { profile in
                    profileCard(for: profile)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func profileCard(for profile: WindowProfile) -> some View {
        let isCurrent = isProfileActive(profile)

        HStack(spacing: 16) {
            Image(systemName: profile.icon)
                .font(.title2)
                .foregroundStyle(isCurrent ? Color.accentColor : Color.secondary)
                .frame(width: 36, height: 36)
                .background(isCurrent ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(profile.name)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    if isCurrent {
                        Text("ACTIVE")
                            .font(.caption2)
                            .fontWeight(.heavy)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
                Text(profile.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Label(profile.layout.displayName, systemImage: profile.layout.iconName)
                    Label("\(profile.windowGap)px gap", systemImage: "arrow.left.and.right")
                    Label("\(profile.padding)px margin", systemImage: "square.inset.filled")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            }

            Spacer()

            if isCurrent {
                Button("Active") {}
                    .buttonStyle(.bordered)
                    .disabled(true)
                    .controlSize(.small)
            } else {
                Button("Apply") {
                    service.applyProfile(profile)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(isCurrent ? 0.8 : 0.4))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isCurrent ? Color.accentColor.opacity(0.6) : Color.secondary.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func isProfileActive(_ profile: WindowProfile) -> Bool {
        service.yabaiConfig.layout == profile.layout &&
        service.yabaiConfig.windowGap == profile.windowGap &&
        service.yabaiConfig.topPadding == profile.padding
    }

    // MARK: - Tab 5: Services & Daemons
    private var servicesTabView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daemon Status & Health").font(.headline)

            HStack(spacing: 20) {
                daemonCard(
                    name: "yabai (Tiling Engine)",
                    isInstalled: service.isYabaiInstalled,
                    isBundled: service.isYabaiBundled,
                    isRunning: service.isYabaiRunning,
                    onStart: { service.startYabai() },
                    onRestart: { service.restartYabai() }
                )
                daemonCard(
                    name: "skhd (Hotkey Daemon)",
                    isInstalled: service.isSkhdInstalled,
                    isBundled: service.isSkhdBundled,
                    isRunning: service.isSkhdRunning,
                    onStart: { service.startSkhd() },
                    onRestart: { service.restartSkhd() }
                )
            }

            Divider()

            Text("Service Controls").font(.subheadline).fontWeight(.medium)
            HStack(spacing: 12) {
                Button("Start Services") {
                    service.startServices()
                }
                .buttonStyle(.borderedProminent)

                Button("Restart Services") {
                    service.restartServices()
                }
                .buttonStyle(.bordered)

                Button("Stop Services", role: .destructive) {
                    service.stopServices()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Symlink CLI to ~/.local/bin") {
                    service.installCLIToolsToUserPath()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Divider()

            if service.hasAccessibilityPermission {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accessibility Permissions Granted")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Text("Yabai has accessibility access to control window frames, spaces, and displays.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Re-check") {
                        service.resetAccessibilityPermissionCheck()
                    }
                    .controlSize(.small)
                }
                .padding(12)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Accessibility Permissions Required", systemImage: "hand.raised.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)

                    Text("Ensure 'YabaiControl', 'yabai', and 'skhd' are granted permissions in:")
                        .font(.caption)
                    Text("System Settings > Privacy & Security > Accessibility")
                        .font(.caption)
                        .bold()

                    HStack(spacing: 8) {
                        Button("Open Accessibility Settings") {
                            service.openAccessibilitySettings()
                        }
                        .controlSize(.small)

                        Button("I've Already Granted Access") {
                            service.acknowledgeAccessibilityPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                        Button("Check Again") {
                            service.checkAccessibility()
                        }
                        .controlSize(.small)
                    }
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Scripting Addition (SA) & SIP Assistant", systemImage: "lock.shield")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    HStack(spacing: 6) {
                        Circle()
                            .fill(service.isSALoaded ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(service.isSALoaded ? "SA Injected" : "SA Not Injected")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("System Integrity Protection: \(service.sipStatusText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if service.isSALoaded {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Scripting addition is loaded. Instant workspace transitions and focus-without-click are active.")
                            .font(.caption)
                    }
                    .padding(10)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("For instant space transitions, yabai injects code into Dock.app. Run this sudoers rule to allow passwordless loading:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text(service.sudoersCommand)
                                .font(.system(.caption2, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .padding(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(nsColor: .textBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 6))

                            Button("Copy Rule") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(service.sudoersCommand, forType: .string)
                            }
                            .controlSize(.small)
                        }

                        HStack(spacing: 8) {
                            Button("Load Scripting Addition") {
                                service.loadScriptingAddition()
                            }
                            .controlSize(.small)
                            .buttonStyle(.borderedProminent)

                            Button("Refresh Status") {
                                service.checkScriptingAddition()
                            }
                            .controlSize(.small)
                        }
                    }
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Software Updates & System Status", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    if service.isCheckingForUpdates {
                        ProgressView()
                            .controlSize(.small)
                    } else if service.isUpdatePendingRestart {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.caption2.weight(.heavy))
                            Text("Restart Required")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Installed Version: \(service.appVersion)")
                            .font(.caption)
                            .foregroundStyle(.primary)

                        Text(service.updateStatusMessage)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Button("Check for Updates") {
                            service.checkForUpdates()
                        }
                        .controlSize(.small)
                        .disabled(service.isCheckingForUpdates)

                        if service.isUpdatePendingRestart {
                            Button("Restart Services") {
                                service.performPendingRestart()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        } else {
                            Button("Test Update Badge") {
                                service.toggleSimulatedUpdate()
                            }
                            .controlSize(.small)
                        }
                    }
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Uninstall Application").font(.subheadline).bold()
                Text("Stops all background daemons, removes launch agents and CLI symlinks, and moves YabaiControl to the Trash.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Uninstall YabaiControl...", role: .destructive) {
                    service.showUninstallAlert = true
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func daemonCard(
        name: String,
        isInstalled: Bool,
        isBundled: Bool,
        isRunning: Bool,
        onStart: @escaping () -> Void,
        onRestart: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name).font(.subheadline).bold()
                Spacer()
                Circle()
                    .fill(isRunning ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }
            HStack(spacing: 6) {
                Text(isBundled ? "Embedded Bundle" : (isInstalled ? "System / Homebrew" : "Not Installed"))
                    .font(.caption2)
                    .foregroundStyle(isInstalled ? .green : .red)
                Text("•")
                Text(isRunning ? "Running" : "Stopped")
                    .font(.caption2)
                    .foregroundStyle(isRunning ? .green : .secondary)
            }
            if isInstalled {
                HStack(spacing: 6) {
                    if !isRunning {
                        Button("Start") {
                            onStart()
                        }
                        .controlSize(.mini)
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Restart") {
                            onRestart()
                        }
                        .controlSize(.mini)
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var saveButton: some View {
        HStack {
            Text(service.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Apply & Save to Configs") {
                service.saveAndApply()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 10)
    }
}
