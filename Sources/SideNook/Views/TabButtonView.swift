// Sources/SideNook/Views/TabButtonView.swift
import SwiftUI

struct TabButtonView: View {
    let session: TerminalSession
    let isActive: Bool
    let isDark: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovered = false

    // MARK: - Palette

    private var fgColor: Color {
        if isActive {
            return isDark ? Color.white.opacity(0.90) : Color.black.opacity(0.85)
        }
        if isHovered {
            return isDark ? Color.white.opacity(0.70) : Color.black.opacity(0.65)
        }
        return isDark ? Color.white.opacity(0.45) : Color.black.opacity(0.42)
    }

    private var tabBg: Color {
        if isActive {
            return isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.06)
        }
        if isHovered {
            return isDark ? Color.white.opacity(0.05) : Color.black.opacity(0.03)
        }
        return Color.clear
    }

    private var accentLine: Color {
        isDark ? Color.white.opacity(0.30) : Color.black.opacity(0.22)
    }

    private var closeFg: Color {
        isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.40)
    }
    private var closeHoverBg: Color {
        isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                // Session status dot
                Circle()
                    .fill(session.isAlive
                        ? (session.isExternal
                            ? Color.blue.opacity(0.6)
                            : Color.green.opacity(0.5))
                        : Color.red.opacity(0.4))
                    .frame(width: 5, height: 5)

                Text(session.title)
                    .font(.system(size: 11.5, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(fgColor)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if isHovered || isActive {
                    Spacer(minLength: 0)

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 7.5, weight: .bold))
                            .foregroundStyle(closeFg)
                            .frame(width: 16, height: 16)
                            .background(closeHoverBg, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.animation(.easeOut(duration: 0.1)))
                }
            }
            .padding(.leading, 8)
            .padding(.trailing, isHovered || isActive ? 5 : 8)
            .frame(height: 28)
            .frame(minWidth: 84, maxWidth: 174)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(tabBg)
            )
            .overlay(alignment: .bottom) {
                if isActive {
                    Capsule()
                        .fill(accentLine)
                        .frame(width: 20, height: 2)
                        .offset(y: 1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .animation(.easeOut(duration: 0.15), value: isActive)
    }
}
