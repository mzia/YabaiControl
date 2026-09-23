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

            servicesTabView
                .tabItem { Label("Services", systemImage: "gearshape.2") }
                .tag(4)
        }
        .padding(20)
        .frame(minWidth: 580, minHeight: 440)
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
            Text("Floating Applications")
                .font(.headline)
            Text("These apps will float freely instead of being partitioned into the tiling grid.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                TextField("Add Application Name (e.g. 1Password)", text: $service.newAppName)
                Button("Add Rule") {
                    let trimmed = service.newAppName.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty && !service.yabaiConfig.floatingApps.contains(trimmed) {
                        service.yabaiConfig.floatingApps.append(trimmed)
                        service.newAppName = ""
                    }
                }
                .disabled(service.newAppName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            List {
                ForEach(service.yabaiConfig.floatingApps, id: \.self) { app in
                    HStack {
                        Label(app, systemImage: "app.dashed")
                        Spacer()
                        Button(role: .destructive) {
                            service.yabaiConfig.floatingApps.removeAll { $0 == app }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
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
                }

                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                    GridRow {
                        Text("Focus Left:").fontWeight(.medium)
                        TextField("", text: $service.skhdConfig.focusLeft).frame(width: 40)

                        Text("Focus Down:").fontWeight(.medium)
                        TextField("", text: $service.skhdConfig.focusDown).frame(width: 40)
                    }
                    GridRow {
                        Text("Focus Up:").fontWeight(.medium)
                        TextField("", text: $service.skhdConfig.focusUp).frame(width: 40)

                        Text("Focus Right:").fontWeight(.medium)
                        TextField("", text: $service.skhdConfig.focusRight).frame(width: 40)
                    }
                    GridRow {
                        Text("Toggle Float:").fontWeight(.medium)
                        TextField("", text: $service.skhdConfig.toggleFloat).frame(width: 40)

                        Text("Balance Sizes:").fontWeight(.medium)
                        TextField("", text: $service.skhdConfig.balanceSizes).frame(width: 40)
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

    // MARK: - Tab 5: Services & Daemons
    private var servicesTabView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daemon Status & Health").font(.headline)

            HStack(spacing: 20) {
                daemonCard(
                    name: "yabai (Tiling Engine)",
                    isInstalled: service.isYabaiInstalled,
                    isBundled: service.isYabaiBundled,
                    isRunning: service.isYabaiRunning
                )
                daemonCard(
                    name: "skhd (Hotkey Daemon)",
                    isInstalled: service.isSkhdInstalled,
                    isBundled: service.isSkhdBundled,
                    isRunning: service.isSkhdRunning
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

                Button("Open Accessibility Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
                .controlSize(.small)
            }
            .padding(12)
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()
        }
    }

    @ViewBuilder
    private func daemonCard(name: String, isInstalled: Bool, isBundled: Bool, isRunning: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name).font(.subheadline).bold()
            HStack(spacing: 6) {
                Text(isBundled ? "Embedded Bundle" : (isInstalled ? "System / Homebrew" : "Not Installed"))
                    .font(.caption2)
                    .foregroundStyle(isInstalled ? .green : .red)
                Text("•")
                Text(isRunning ? "Running" : "Stopped")
                    .font(.caption2)
                    .foregroundStyle(isRunning ? .green : .secondary)
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
