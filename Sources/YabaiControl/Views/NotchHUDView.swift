import SwiftUI
import AppKit

public struct NotchHUDData: Equatable {
    public var appName: String
    public var windowTitle: String
    public var spaceIndex: Int
    public var layout: YabaiLayout
    public var appIcon: NSImage?

    public init(
        appName: String = "",
        windowTitle: String = "",
        spaceIndex: Int = 1,
        layout: YabaiLayout = .bsp,
        appIcon: NSImage? = nil
    ) {
        self.appName = appName
        self.windowTitle = windowTitle
        self.spaceIndex = spaceIndex
        self.layout = layout
        self.appIcon = appIcon
    }
}

public struct NotchHUDView: View {
    public var data: NotchHUDData

    public init(data: NotchHUDData) {
        self.data = data
    }

    public var body: some View {
        HStack(spacing: 10) {
            // App Icon
            if let icon = data.appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
            } else {
                Image(systemName: data.layout.iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }

            // Window Title & App Name
            VStack(alignment: .leading, spacing: 1) {
                if !data.appName.isEmpty {
                    Text(data.appName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                if !data.windowTitle.isEmpty && data.windowTitle != data.appName {
                    Text(data.windowTitle)
                        .font(.system(size: 9.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: 160, alignment: .leading)
                }
            }

            Spacer(minLength: 4)

            // Space Badge
            HStack(spacing: 3) {
                Image(systemName: "macwindow")
                    .font(.system(size: 9))
                Text("S\(data.spaceIndex)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(Color.secondary.opacity(0.15))
            .clipShape(Capsule())

            // Layout Pill
            HStack(spacing: 3) {
                Image(systemName: data.layout.iconName)
                    .font(.system(size: 9))
                Text(data.layout.rawValue.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(Color.accentColor.opacity(0.15))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .frame(minWidth: 260, maxWidth: 380, minHeight: 38, maxHeight: 38)
        .background(
            RoundedRectangle(cornerRadius: 19)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 19)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}
