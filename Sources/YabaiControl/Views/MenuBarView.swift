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
                }
                .padding(6)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else if !service.isYabaiRunning || !service.isSkhdRunning {
                HStack(spacing: 6) {
                    Image(systemName: "pause.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text("Background daemons stopped")
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
                    shortcutRow(keys: "⌥ + T", action: "Toggle Float / Tile")
                    shortcutRow(keys: "⌥ + E", action: "Toggle Split (H / V)")
                    shortcutRow(keys: "⌥ + B", action: "Balance Window Sizes")
                    shortcutRow(keys: "⌥ + 1–5", action: "Switch Workspace")
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
}
