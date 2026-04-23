// Sources/SideNook/Views/ShortcutsListView.swift
import SwiftUI

struct ShortcutsListView: View {
    let isDark: Bool

    private var fg: Color {
        isDark ? Color.white.opacity(0.85) : Color.black.opacity(0.85)
    }
    private var fgMuted: Color {
        isDark ? Color.white.opacity(0.45) : Color.black.opacity(0.45)
    }
    private var badgeBg: Color {
        isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.07)
    }

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
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(shortcuts, id: \.key) { shortcut in
                HStack {
                    Text(shortcut.key)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(fg)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(badgeBg)
                        )
                        .frame(width: 64, alignment: .center)

                    Text(shortcut.action)
                        .font(.system(size: 13))
                        .foregroundStyle(fgMuted)

                    Spacer()
                }
            }
        }
        .padding(12)
    }
}
