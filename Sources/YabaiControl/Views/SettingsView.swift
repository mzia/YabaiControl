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
                .tabItem { Label("Appearance & Gaps", systemImage: "slider.horizontal.2.square") }
                .tag(1)

            rulesTabView
                .tabItem { Label("Window Rules", systemImage: "macwindow.on.rectangle") }
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

            Section(header: Text("Window Appearance & Styling").font(.headline)) {
                Picker("Window Shadows", selection: $service.yabaiConfig.windowShadow) {
                    ForEach(WindowShadowMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Insertion Feedback Color:")
                            .font(.caption)
                            .fontWeight(.medium)
                        Circle()
                            .fill(Color(hexARGB: service.yabaiConfig.insertFeedbackColor))
                            .frame(width: 14, height: 14)
                        Text(service.yabaiConfig.insertFeedbackColor)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 6) {
                        Text("Presets:").font(.caption2).foregroundStyle(.secondary)
                        feedbackColorPreset(name: "Neon Green", hex: "0xff50fa7b")
                        feedbackColorPreset(name: "Cyan", hex: "0xff8be9fd")
                        feedbackColorPreset(name: "Purple", hex: "0xffbd93f9")
                        feedbackColorPreset(name: "Gold", hex: "0xfff1fa8c")
                        feedbackColorPreset(name: "Coral", hex: "0xffff5555")
                    }
                }
            }

            Section(header: Text("Window Opacity & Focus Dimming").font(.headline)) {
                Toggle("Enable Inactive Window Dimming", isOn: $service.yabaiConfig.windowOpacity)

                if service.yabaiConfig.windowOpacity {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Active Window Opacity: \(Int(service.yabaiConfig.activeOpacity * 100))%")
                                .frame(width: 200, alignment: .leading)
                            Slider(value: $service.yabaiConfig.activeOpacity, in: 0.5...1.0, step: 0.05)
                        }

                        HStack {
                            Text("Inactive Window Opacity: \(Int(service.yabaiConfig.normalOpacity * 100))%")
                                .frame(width: 200, alignment: .leading)
                            Slider(value: $service.yabaiConfig.normalOpacity, in: 0.4...1.0, step: 0.05)
                        }

                        HStack {
                            Text("Transition Duration: \(String(format: "%.2f", service.yabaiConfig.windowOpacityDuration))s")
                                .frame(width: 200, alignment: .leading)
                            Slider(value: $service.yabaiConfig.windowOpacityDuration, in: 0.0...0.5, step: 0.05)
                        }

                        // Live visual preview
                        HStack(spacing: 12) {
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(nsColor: .controlAccentColor))
                                    .opacity(service.yabaiConfig.activeOpacity)
                                    .frame(height: 48)
                                    .overlay(
                                        Text("Active Window")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                    )
                                Text("Focused (\(Int(service.yabaiConfig.activeOpacity * 100))%)")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }

                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(nsColor: .windowBackgroundColor))
                                    .opacity(service.yabaiConfig.normalOpacity)
                                    .frame(height: 48)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                                    .overlay(
                                        Text("Inactive Window")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    )
                                Text("Dimmed (\(Int(service.yabaiConfig.normalOpacity * 100))%)")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            Spacer()

            saveButton
        }
    }

    // MARK: - Tab 3: Window Rules & Routing
    private var rulesTabView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Rules Category", selection: $service.rulesSegment) {
                Text("Custom Rules (\(service.yabaiConfig.customRules.count))").tag(0)
                Text("Quick Floating Apps (\(service.yabaiConfig.floatingApps.count))").tag(1)
            }
            .pickerStyle(.segmented)

            if service.rulesSegment == 0 {
                customRulesView
            } else {
                quickFloatingAppsView
            }

            Spacer()

            saveButton
        }
    }

    private var customRulesView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Visual Window Routing Rules")
                        .font(.headline)
                    Text("Auto-assign apps and titles to specific spaces, displays, floating states, or sublayers.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    service.showingAddRuleForm.toggle()
                } label: {
                    Label(service.showingAddRuleForm ? "Hide Form" : "Add Rule", systemImage: service.showingAddRuleForm ? "chevron.up" : "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("Load Presets") {
                    service.loadDefaultRules()
                }
                .controlSize(.small)
            }

            if service.showingAddRuleForm {
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Window Rule").font(.subheadline).bold()

                    HStack(spacing: 8) {
                        TextField("App Regex (e.g. ^Slack$)", text: $service.newRuleApp)
                            .textFieldStyle(.roundedBorder)

                        TextField("Title Regex (e.g. ^Picture in Picture$)", text: $service.newRuleTitle)
                            .textFieldStyle(.roundedBorder)
                    }

                    HStack(spacing: 12) {
                        Picker("Space:", selection: $service.newRuleSpace) {
                            Text("Any Space").tag(0)
                            ForEach(1...10, id: \.self) { sp in
                                Text("Space \(sp)").tag(sp)
                            }
                        }
                        .frame(width: 130)

                        Picker("Display:", selection: $service.newRuleDisplay) {
                            Text("Any Display").tag(0)
                            ForEach(1...4, id: \.self) { d in
                                Text("Display \(d)").tag(d)
                            }
                        }
                        .frame(width: 130)

                        Picker("Manage:", selection: $service.newRuleManage) {
                            Text("Default").tag(0)
                            Text("Tile (manage=on)").tag(1)
                            Text("Float (manage=off)").tag(2)
                        }
                        .frame(width: 150)
                    }

                    HStack(spacing: 12) {
                        Picker("Sub-Layer:", selection: $service.newRuleSubLayer) {
                            Text("Default").tag("default")
                            Text("Below (Desktop)").tag("below")
                            Text("Normal").tag("normal")
                            Text("Above (Always on Top)").tag("above")
                        }
                        .frame(width: 170)

                        Toggle("Sticky (All Spaces)", isOn: $service.newRuleSticky)
                            .toggleStyle(.checkbox)

                        Spacer()

                        Button("Cancel") {
                            service.resetNewRuleFields()
                        }
                        .controlSize(.small)

                        Button("Save Rule") {
                            service.commitNewRule()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(service.newRuleApp.trimmingCharacters(in: .whitespaces).isEmpty && service.newRuleTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
            }

            if service.yabaiConfig.customRules.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "macwindow.badge.plus")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No custom rules configured yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Add Default System & App Rules") {
                        service.loadDefaultRules()
                    }
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity, maxHeight: 150)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                List {
                    ForEach(service.yabaiConfig.customRules) { rule in
                        ruleCard(rule)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    @ViewBuilder
    private func ruleCard(_ rule: YabaiRule) -> some View {
        HStack(spacing: 8) {
            Toggle("", isOn: Binding(
                get: { rule.isEnabled },
                set: { _ in service.toggleCustomRule(id: rule.id) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.mini)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if !rule.app.isEmpty {
                        badgeView(text: "app: \(rule.app)", color: .blue)
                    }
                    if !rule.title.isEmpty {
                        badgeView(text: "title: \(rule.title)", color: .purple)
                    }
                    if let sp = rule.space {
                        badgeView(text: "space \(sp)", color: .orange)
                    }
                    if let dp = rule.display {
                        badgeView(text: "disp \(dp)", color: .teal)
                    }
                    if let mg = rule.manage {
                        badgeView(text: mg ? "tile" : "float", color: mg ? .green : .yellow)
                    }
                    if rule.sticky == true {
                        badgeView(text: "sticky", color: .indigo)
                    }
                    if let sub = rule.subLayer {
                        badgeView(text: "\(sub)-layer", color: .brown)
                    }
                }

                Text(rule.summaryText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(role: .destructive) {
                service.removeCustomRule(id: rule.id)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func badgeView(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var quickFloatingAppsView: some View {
        VStack(alignment: .leading, spacing: 10) {
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
        }
    }

    // MARK: - Tab 4: Shortcuts (skhd)
    private var shortcutsTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header & Modifier Picker
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Keyboard Hotkeys (skhd)").font(.headline)
                        Text("Configure directional navigation, window movement, multi-display, and grid snapping shortcuts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

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
                            service.skhdConfig.warpLeft = "h"
                            service.skhdConfig.warpDown = "j"
                            service.skhdConfig.warpUp = "k"
                            service.skhdConfig.warpRight = "l"
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
                            service.skhdConfig.warpLeft = "left"
                            service.skhdConfig.warpDown = "down"
                            service.skhdConfig.warpUp = "up"
                            service.skhdConfig.warpRight = "right"
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
                            service.skhdConfig.warpLeft = "a"
                            service.skhdConfig.warpDown = "s"
                            service.skhdConfig.warpUp = "w"
                            service.skhdConfig.warpRight = "d"
                        }
                        .controlSize(.mini)
                    }
                }

                HStack {
                    Text("Primary Modifier:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Picker("", selection: $service.skhdConfig.primaryModifier) {
                        Text("Option / Alt (⌥) [Recommended]").tag("alt")
                        Text("Command (⌘)").tag("cmd")
                        Text("Control + Option (⌃⌥)").tag("ctrl + alt")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 250)
                }

                Divider()

                // Section 1: Directional Focus, Swap & Warp
                VStack(alignment: .leading, spacing: 10) {
                    Text("Directional Navigation & Window Movement")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                        GridRow {
                            Text("Focus West:").font(.caption).fontWeight(.medium)
                            ShortcutRecorderView(id: "focusLeft", key: $service.skhdConfig.focusLeft, modifier: service.skhdConfig.primaryModifier, width: 62)

                            Text("Focus South:").font(.caption).fontWeight(.medium)
                            ShortcutRecorderView(id: "focusDown", key: $service.skhdConfig.focusDown, modifier: service.skhdConfig.primaryModifier, width: 62)

                            Text("Focus North:").font(.caption).fontWeight(.medium)
                            ShortcutRecorderView(id: "focusUp", key: $service.skhdConfig.focusUp, modifier: service.skhdConfig.primaryModifier, width: 62)

                            Text("Focus East:").font(.caption).fontWeight(.medium)
                            ShortcutRecorderView(id: "focusRight", key: $service.skhdConfig.focusRight, modifier: service.skhdConfig.primaryModifier, width: 62)
                        }
                    }

                    Text("• Focus: [ Modifier + Key ]  |  • Swap: [ ⇧ Shift + Modifier + Key ]")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Toggle(isOn: $service.skhdConfig.enableWindowWarp) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable Window Warp (Tree Re-Parenting)")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("Moves and re-parents window into the target branch of the BSP tree via [ ⌃ Control + Modifier + Key ].")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.checkbox)
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Section 2: Multi-Display & Space Navigation
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Multi-Display & Space Navigation")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Toggle("Enabled", isOn: $service.skhdConfig.enableDisplayShortcuts)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                    }

                    if service.skhdConfig.enableDisplayShortcuts {
                        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                            GridRow {
                                Text("Next Display:").font(.caption).fontWeight(.medium)
                                ShortcutRecorderView(id: "displayNext", key: $service.skhdConfig.displayNext, modifier: service.skhdConfig.primaryModifier, width: 62)

                                Text("Prev Display:").font(.caption).fontWeight(.medium)
                                ShortcutRecorderView(id: "displayPrev", key: $service.skhdConfig.displayPrev, modifier: service.skhdConfig.primaryModifier, width: 62)

                                Text("Display 1:").font(.caption).fontWeight(.medium)
                                ShortcutRecorderView(id: "display1", key: $service.skhdConfig.display1, modifier: service.skhdConfig.primaryModifier, width: 62)

                                Text("Display 2:").font(.caption).fontWeight(.medium)
                                ShortcutRecorderView(id: "display2", key: $service.skhdConfig.display2, modifier: service.skhdConfig.primaryModifier, width: 62)
                            }
                        }

                        Text("• Move & Follow Display: [ ⌃ Control + Modifier + Key ]  |  • Focus Display: [ Modifier + Key ]")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    Toggle(isOn: $service.skhdConfig.enableSpaceFollowShortcuts) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Move Window to Next / Prev Space & Follow Focus")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("Sends active window to next/previous workspace and follows focus via [ ⌃ Control + ⇧ Shift + ← / → ].")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.checkbox)
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Section 3: Screen Grid Snapping & Resizing
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Screen Grid Snapping & Resizing")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Toggle("Enabled", isOn: $service.skhdConfig.enableGridSnapping)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                    }

                    if service.skhdConfig.enableGridSnapping {
                        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                            GridRow {
                                Text("Snap Left:").font(.caption).fontWeight(.medium)
                                ShortcutRecorderView(id: "snapLeft", key: $service.skhdConfig.snapLeft, modifier: service.skhdConfig.primaryModifier, width: 62)

                                Text("Snap Right:").font(.caption).fontWeight(.medium)
                                ShortcutRecorderView(id: "snapRight", key: $service.skhdConfig.snapRight, modifier: service.skhdConfig.primaryModifier, width: 62)

                                Text("Maximize:").font(.caption).fontWeight(.medium)
                                ShortcutRecorderView(id: "snapMaximize", key: $service.skhdConfig.snapMaximize, modifier: service.skhdConfig.primaryModifier, width: 62)

                                Text("Center:").font(.caption).fontWeight(.medium)
                                ShortcutRecorderView(id: "snapCenter", key: $service.skhdConfig.snapCenter, modifier: service.skhdConfig.primaryModifier, width: 62)
                            }
                        }

                        Text("• Grid Snap Shortcuts: [ ⌃ Control + Modifier + Key ]")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    Toggle(isOn: $service.skhdConfig.enableWindowResize) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fine-Grain Window Resizing")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("Expands/shrinks active window splits in 30px steps via [ ⌘ Command + Modifier + Directional Key ].")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .toggleStyle(.checkbox)
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Section 4: Window Toggles & Utilities
                VStack(alignment: .leading, spacing: 10) {
                    Text("Window Toggles & Utilities")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                        GridRow {
                            Text("Toggle Float:").font(.caption).fontWeight(.medium)
                            ShortcutRecorderView(id: "toggleFloat", key: $service.skhdConfig.toggleFloat, modifier: service.skhdConfig.primaryModifier, width: 62)

                            Text("Toggle Split:").font(.caption).fontWeight(.medium)
                            ShortcutRecorderView(id: "toggleSplit", key: $service.skhdConfig.toggleSplit, modifier: service.skhdConfig.primaryModifier, width: 62)

                            Text("Balance Sizes:").font(.caption).fontWeight(.medium)
                            ShortcutRecorderView(id: "balanceSizes", key: $service.skhdConfig.balanceSizes, modifier: service.skhdConfig.primaryModifier, width: 62)

                            Text("Restart Yabai:").font(.caption).fontWeight(.medium)
                            ShortcutRecorderView(id: "restartYabai", key: $service.skhdConfig.restartYabai, modifier: service.skhdConfig.primaryModifier, width: 62)
                        }
                    }

                    Text("• Toggles: [ Modifier + Key ]  |  • Restart Yabai: [ ⇧ Shift + Modifier + Key ]")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                saveButton
            }
            .padding(12)
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

    @ViewBuilder
    private func feedbackColorPreset(name: String, hex: String) -> some View {
        Button {
            service.yabaiConfig.insertFeedbackColor = hex
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color(hexARGB: hex))
                    .frame(width: 8, height: 8)
                Text(name)
                    .font(.caption2)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(service.yabaiConfig.insertFeedbackColor.lowercased() == hex.lowercased() ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(service.yabaiConfig.insertFeedbackColor.lowercased() == hex.lowercased() ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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

extension Color {
    init(hexARGB hex: String) {
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanHex.hasPrefix("0x") || cleanHex.hasPrefix("0X") {
            cleanHex = String(cleanHex.dropFirst(2))
        } else if cleanHex.hasPrefix("#") {
            cleanHex = String(cleanHex.dropFirst(1))
        }

        var intVal: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&intVal)

        let a, r, g, b: Double
        if cleanHex.count == 8 {
            a = Double((intVal >> 24) & 0xff) / 255.0
            r = Double((intVal >> 16) & 0xff) / 255.0
            g = Double((intVal >> 8) & 0xff) / 255.0
            b = Double(intVal & 0xff) / 255.0
        } else if cleanHex.count == 6 {
            a = 1.0
            r = Double((intVal >> 16) & 0xff) / 255.0
            g = Double((intVal >> 8) & 0xff) / 255.0
            b = Double(intVal & 0xff) / 255.0
        } else {
            a = 1.0; r = 0.3; g = 0.8; b = 0.5
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
