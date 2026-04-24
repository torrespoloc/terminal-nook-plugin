// Sources/SideNook/Views/TerminalContainerView.swift
import SwiftUI

/// Hosts the active terminal session with matched inner radius.
/// Overlays a transparent input-highlight layer and a dead-session recovery UI.
struct TerminalContainerView: View {
    let session: TerminalSession
    let isDark: Bool

    var body: some View {
        ZStack {
            TerminalSessionView(session: session)
                .id(session.id)
                .contextMenu {
                    Button("Copy") { session.terminalView.copy(session.terminalView) }
                    Button("Paste") { session.terminalView.paste(session.terminalView) }
                    Divider()
                    Button("Select All") { session.terminalView.selectAll(session.terminalView) }
                }

            InputHighlightView(session: session, isDark: isDark)
                .allowsHitTesting(false)

            if !session.isAlive {
                DeadSessionOverlay(isDark: isDark) {
                    session.restart()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Dead Session Overlay

private struct DeadSessionOverlay: View {
    let isDark: Bool
    let onRestart: () -> Void

    private var bg: Color {
        isDark ? Color.black.opacity(0.70) : Color.white.opacity(0.80)
    }
    private var fg: Color {
        isDark ? Color.white.opacity(0.85) : Color.black.opacity(0.80)
    }
    private var fgMuted: Color {
        isDark ? Color.white.opacity(0.45) : Color.black.opacity(0.45)
    }
    private var buttonBg: Color {
        isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }
    private var buttonHoverBg: Color {
        isDark ? Color.white.opacity(0.20) : Color.black.opacity(0.13)
    }

    @State private var isHovered = false

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "terminal")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(fgMuted)

                Text("Session ended")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(fg)

                Button(action: onRestart) {
                    Text("Restart")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(fg)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isHovered ? buttonHoverBg : buttonBg)
                        )
                }
                .buttonStyle(.plain)
                .onHover { isHovered = $0 }
            }
        }
        .transition(.opacity.animation(.easeIn(duration: 0.15)))
    }
}
