// Sources/SideNook/Views/ShortcutsListView.swift
import SwiftUI

struct ShortcutsListView: View {
    let isDark: Bool

    private var t: NookTheme { NookTheme(isDark: isDark) }
    private var fg: Color { t.fg }
    private var fgMuted: Color { t.iconFgMute }
    private var badgeBg: Color { t.hoverBg }

    private let shortcuts: [(key: String, action: String)] = [
        ("\u{2303}`",           "Show / Hide"),
        ("\u{2318}T",           "New Tab"),
        ("\u{2318}W",           "Close Tab"),
        ("\u{2318}\u{21E7}[",   "Previous Tab"),
        ("\u{2318}\u{21E7}]",   "Next Tab"),
        ("\u{2318}1–9",         "Jump to Tab"),
        ("\u{2318}K",           "Clear Screen"),
        ("\u{2318}+",           "Zoom In"),
        ("\u{2318}\u{2212}",    "Zoom Out"),
        ("\u{2318}0",           "Reset Zoom"),
        ("\u{2318}C",           "Copy selection"),
        ("\u{2318}V",           "Paste"),
    ]

    private let notesShortcuts: [(key: String, action: String)] = [
        ("\u{2318}C",   "Copy selected text"),
        ("\u{2318}V",   "Paste"),
        ("\u{2318}X",   "Cut"),
        ("\u{2318}Z",   "Undo"),
        ("\u{2318}A",   "Select All"),
        ("\u{2318}Z\u{21E7}", "Redo"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(shortcuts, id: \.key) { shortcut in
                shortcutRow(shortcut)
            }

            Divider().padding(.vertical, 4)

            Text("Notes")
                .font(NookType.captionStrong)
                .foregroundStyle(fgMuted)

            ForEach(notesShortcuts, id: \.key) { shortcut in
                shortcutRow(shortcut)
            }

            Divider().padding(.vertical, 4)

            Text("System text shortcuts also apply — three-finger drag, double-tap select, and any custom Accessibility Pointer shortcuts you've configured in System Settings.")
                .font(NookType.caption)
                .foregroundStyle(fgMuted.opacity(0.4))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
    }

    @ViewBuilder
    private func shortcutRow(_ shortcut: (key: String, action: String)) -> some View {
        HStack {
            Text(shortcut.key)
                .font(NookType.labelMono)
                .foregroundStyle(fg)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                        .fill(badgeBg)
                )
                .frame(width: 64, alignment: .center)

            Text(shortcut.action)
                .font(NookType.bodyReg)
                .foregroundStyle(fgMuted)

            Spacer()
        }
    }
}
