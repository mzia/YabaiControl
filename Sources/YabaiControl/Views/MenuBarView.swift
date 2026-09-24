import SwiftUI

public struct MenuBarView: View {
    @EnvironmentObject private var service: YabaiService
    @Environment(\.openWindow) private var openWindow

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Daemon Status Badges
            HStack {
                Label("YabaiControl", systemImage: "squareshape.split.2x2")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                HStack(spacing: 6) {
                    statusPill(name: "yabai", isRunning: service.isYabaiRunning)
                    statusPill(name: "skhd", isRunning: service.isSkhdRunning)
                }
            }

            if service.isUpdatePendingRestart {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(service.updateVersion.isEmpty ? "Update Ready" : "Update v\(service.updateVersion) Ready")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Restart required to apply changes.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Restart") {
                        service.performPendingRestart()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                }
                .padding(8)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if service.isTilingSuspendedForStageManager {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.3.group.fill")
                        .font(.title3)
                        .foregroundStyle(Color.cyan)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Stage Manager Active")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Tiling suspended for native OS behavior.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Resume") {
                        service.resumeTilingFromStageManager()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
                .padding(8)
                .background(Color.cyan.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if !service.hasAccessibilityPermission {
                HStack(spacing: 6) {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text("Accessibility permission required")
                        .font(.caption2)
                        .lineLimit(1)
                    Spacer()
                    Button("Grant") {
                        service.openAccessibilitySettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)

                    Button("Already Granted") {
                        service.acknowledgeAccessibilityPermission()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
                .padding(6)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else if !service.isYabaiRunning || !service.isSkhdRunning {
                HStack(spacing: 6) {
                    Image(systemName: "pause.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text(
                        !service.isYabaiRunning && !service.isSkhdRunning
                            ? "Background daemons stopped"
                            : (!service.isYabaiRunning ? "yabai daemon stopped" : "skhd daemon stopped")
                    )
                    .font(.caption2)
                    .lineLimit(1)
                    Spacer()
                    Button("Start") {
                        service.startServices()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                }
                .padding(6)
                .background(Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Divider()

            // Quick Window Switcher (Option D)
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)

                TextField("Quick switch window...", text: $service.windowSearchText)
                    .textFieldStyle(.plain)
                    .font(.caption)

                if !service.windowSearchText.isEmpty {
                    Button {
                        service.windowSearchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            if !service.windowSearchText.isEmpty {
                let filteredWindows = service.allWindows.filter {
                    $0.app.localizedCaseInsensitiveContains(service.windowSearchText) ||
                    $0.title.localizedCaseInsensitiveContains(service.windowSearchText)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Matching Windows (\(filteredWindows.count))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    if filteredWindows.isEmpty {
                        Text("No matching windows found")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ScrollView {
                            VStack(spacing: 4) {
                                ForEach(filteredWindows) { win in
                                    Button {
                                        service.focusWindow(id: win.id, space: win.space)
                                        service.windowSearchText = ""
                                    } label: {
                                        HStack(spacing: 8) {
                                            if let icon = service.appIcon(for: win.app) {
                                                Image(nsImage: icon)
                                                    .resizable()
                                                    .frame(width: 16, height: 16)
                                            } else {
                                                Image(systemName: "macwindow")
                                                    .frame(width: 16, height: 16)
                                            }

                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(win.app)
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .lineLimit(1)
                                                if !win.title.isEmpty {
                                                    Text(win.title)
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                        .lineLimit(1)
                                                }
                                            }

                                            Spacer()

                                            Text("S\(win.space)")
                                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 2)
                                                .background(win.space == service.activeSpaceIndex ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.15))
                                                .foregroundStyle(win.space == service.activeSpaceIndex ? Color.accentColor : Color.primary)
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                        }
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 6)
                                        .background(Color(nsColor: .controlBackgroundColor))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxHeight: 160)
                    }
                }
            }

            Divider()

            // Feature 1: Interactive Workspace / Space Switcher (Option C)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Workspaces")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Spacer()

                    HStack(spacing: 4) {
                        Button {
                            service.switchToPreviousSpace()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                        .help("Previous Space")

                        Text("Space \(service.activeSpaceIndex)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.accentColor)

                        Button {
                            service.switchToNextSpace()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                        .help("Next Space")
                    }
                }

                HStack(spacing: 6) {
                    let spacesList = service.spaces.isEmpty ? (1...5).map { YabaiSpace(id: $0, index: $0, type: "bsp", hasFocus: $0 == service.activeSpaceIndex) } : service.spaces
                    ForEach(spacesList) { space in
                        Button {
                            service.focusSpace(index: space.index)
                        } label: {
                            VStack(spacing: 1) {
                                Text("\(space.index)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                if space.windows.count > 0 {
                                    Circle()
                                        .fill(space.index == service.activeSpaceIndex ? Color.white : Color.secondary)
                                        .frame(width: 3, height: 3)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 24)
                            .background(space.index == service.activeSpaceIndex ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                            .foregroundStyle(space.index == service.activeSpaceIndex ? Color.white : Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            // Feature 2: Visual Quick-Snap Grid
            VStack(alignment: .leading, spacing: 6) {
                Text("Quick Snap Window")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                HStack(spacing: 6) {
                    snapButton(position: .leftHalf)
                    snapButton(position: .rightHalf)
                    snapButton(position: .topHalf)
                    snapButton(position: .bottomHalf)
                    snapButton(position: .center)
                    snapButton(position: .maximize)
                }
            }

            Divider()

            // Quick Layout Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Layout Mode")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                HStack(spacing: 8) {
                    ForEach(YabaiLayout.allCases) { layout in
                        Button {
                            service.setLayout(layout)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: layout.iconName)
                                    .font(.system(size: 15))
                                Text(layout.displayName)
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(service.yabaiConfig.layout == layout ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                            .foregroundStyle(service.yabaiConfig.layout == layout ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            // Feature 4: Workflow Profiles
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Workflow Profile")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                }

                HStack(spacing: 6) {
                    ForEach(WindowProfile.presets.prefix(4)) { profile in
                        Button {
                            service.applyProfile(profile)
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: profile.icon)
                                    .font(.system(size: 12))
                                Text(profile.name)
                                    .font(.system(size: 9))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(service.activeProfileId == profile.id ? Color.accentColor.opacity(0.2) : Color(nsColor: .controlBackgroundColor))
                            .foregroundStyle(service.activeProfileId == profile.id ? Color.accentColor : Color.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(service.activeProfileId == profile.id ? Color.accentColor : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider()

            // Key Shortcut Mapping
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Key Shortcut Mapping")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    Text("Modifier: ⌥ Option")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 4) {
                    shortcutRow(keys: "⌥ + H/J/K/L", action: "Focus West / South / North / East")
                    shortcutRow(keys: "⇧⌥ + H/J/K/L", action: "Swap Window Direction")
                    shortcutRow(keys: "⌃⌥ + H/J/K/L", action: "Warp Window to Tree Node")
                    shortcutRow(keys: "⌃⌥ + N / P", action: "Move to Next / Prev Display")
                    shortcutRow(keys: "⌃⌥ + ← / →", action: "Snap Window Left / Right Half")
                    shortcutRow(keys: "⌃⌥ + M", action: "Toggle Fullscreen / Zoom")
                    shortcutRow(keys: "⌃⇧ + ← / →", action: "Move Space & Follow Focus")
                    shortcutRow(keys: "⌥ + T / E / B", action: "Float / Split / Balance Window")
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Divider()

            // Quick Action Buttons
            VStack(spacing: 6) {
                Button {
                    service.balanceSizes()
                } label: {
                    Label("Balance Window Sizes", systemImage: "arrow.left.and.right.square")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderless)

                Button {
                    service.toggleActiveWindowFloat()
                } label: {
                    Label("Toggle Active Window Float", systemImage: "macwindow.badge.plus")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderless)

                Toggle(isOn: $service.yabaiConfig.mouseFollowsFocus) {
                    Label("Mouse Follows Focus", systemImage: "cursorarrow.motionlines")
                }
                .toggleStyle(.switch)
                .onChange(of: service.yabaiConfig.mouseFollowsFocus) { _, _ in
                    service.applyLiveSettings()
                }
            }

            Divider()

            // Service Management & Preferences
            HStack {
                Button {
                    service.restartServices()
                } label: {
                    Label("Restart Daemons", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .font(.caption)

                Spacer()

                Button {
                    openWindow(id: "settings")
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Label("Preferences...", systemImage: "gearshape")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            HStack {
                Text(service.statusMessage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Uninstall...") {
                    service.showUninstallAlert = true
                }
                .font(.caption2)
                .buttonStyle(.plain)
                .foregroundStyle(.red)

                Text("•")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.caption2)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(width: 330)
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
        .onAppear {
            service.refreshAllState()
        }
    }

    @ViewBuilder
    private func statusPill(name: String, isRunning: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isRunning ? Color.green : Color.red)
                .frame(width: 7, height: 7)
            Text(name)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func shortcutRow(keys: String, action: String) -> some View {
        HStack {
            Text(keys)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
            Spacer()
            Text(action)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func snapButton(position: WindowSnapPosition) -> some View {
        Button {
            service.snapActiveWindow(to: position)
        } label: {
            Image(systemName: position.iconName)
                .font(.system(size: 13))
                .frame(maxWidth: .infinity, minHeight: 26)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
        .help("Snap window: \(position.rawValue)")
    }
}
