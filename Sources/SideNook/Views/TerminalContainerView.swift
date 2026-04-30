// Sources/SideNook/Views/TerminalContainerView.swift
import SwiftUI

/// Hosts the active terminal session with matched inner radius.
/// Overlays a dead-session recovery UI when the shell process exits.
struct TerminalContainerView: View {
    let session: TerminalSession
    let isDark: Bool
    var state: NookState? = nil

    var body: some View {
        ZStack(alignment: .top) {
            TerminalSessionView(session: session)
                .id(session.id)
                .contextMenu {
                    Button("Copy") { session.terminalView.copy(session.terminalView) }
                    Button("Paste") { session.terminalView.paste(session.terminalView) }
                    Divider()
                    Button("Select All") { session.terminalView.selectAll(session.terminalView) }
                }

            if !session.isAlive {
                DeadSessionOverlay(isDark: isDark) {
                    session.restart()
                }
            } else {
                ScrollButtons(session: session, isDark: isDark)
            }

            if let state, state.findVisible {
                FindBarView(state: state, session: session)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: NookRadius.lg, style: .continuous))
        .animation(.easeOut(duration: 0.16), value: state?.findVisible ?? false)
    }
}

// MARK: - Scroll Buttons

private struct ScrollButtons: View {
    let session: TerminalSession
    let isDark: Bool

    @State private var hoveredArrow: Arrow? = nil
    @State private var isScrolledUp: Bool = false
    @State private var hasUnreadContent: Bool = false
    @State private var scrolledUpOutputBaseline: Int = 0
    private var t: NookTheme { NookTheme(isDark: isDark) }

    private enum Arrow: Equatable { case up, down }

    /// 0.5s poll is responsive enough to flip the down-arrow blue when output streams in,
    /// and cheap enough to not measurably affect CPU.
    private let pulse = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 8) {
            arrowButton(.up,   icon: "chevron.up")
            arrowButton(.down, icon: "chevron.down")
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .onReceive(pulse) { _ in
            let next = session.terminalView.canScroll && session.terminalView.scrollPosition < 1.0
            if next != isScrolledUp {
                withAnimation(.easeOut(duration: 0.18)) { isScrolledUp = next }
                if next {
                    scrolledUpOutputBaseline = session.terminalView.outputCount
                    hasUnreadContent = false
                } else {
                    hasUnreadContent = false
                }
            } else if isScrolledUp && !hasUnreadContent {
                if session.terminalView.outputCount > scrolledUpOutputBaseline {
                    withAnimation(.easeOut(duration: 0.18)) { hasUnreadContent = true }
                }
            }
        }
    }

    private func arrowButton(_ arrow: Arrow, icon: String) -> some View {
        let isCTA = (arrow == .down) && isScrolledUp
        let isUrgent = isCTA && hasUnreadContent
        let isHover = (hoveredArrow == arrow)
        let bg: Color = {
            if isUrgent { return isHover ? t.scrollCTABgUrgentHover : t.scrollCTABgUrgent }
            if isCTA    { return isHover ? t.scrollCTABgHover        : t.scrollCTABg }
            return isHover ? t.arrowBgHover : t.arrowBg
        }()
        let fg: Color = isCTA ? t.ctaFg : t.iconFg

        return Button {
            smoothScroll(direction: arrow)
        } label: {
            Image(systemName: icon)
                .font(NookType.microStrong)
                .foregroundStyle(fg)
                .frame(width: 24, height: 24)
                .background(Capsule(style: .continuous).fill(bg))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(isCTA ? t.ctaBorder : Color.clear, lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(isCTA ? 0.20 : 0.14), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredArrow = hovering ? arrow : (hoveredArrow == arrow ? nil : hoveredArrow)
        }
        .animation(.easeOut(duration: 0.12), value: isHover)
        .animation(.easeOut(duration: 0.18), value: isCTA)
        .animation(.easeOut(duration: 0.18), value: isUrgent)
    }

    /// Animates SwiftTerm scroll over ~240ms in 12 small chunks for a smooth feel.
    /// SwiftTerm clamps both directions internally — at the buffer edge each chunk is a no-op.
    private func smoothScroll(direction: Arrow) {
        let stepCount = 12
        let stepNanos: UInt64 = 20_000_000  // 20ms
        let linesPerStep = 200
        let session = self.session

        Task { @MainActor in
            for _ in 0..<stepCount {
                switch direction {
                case .up:   session.terminalView.scrollUp(lines: linesPerStep)
                case .down: session.terminalView.scrollDown(lines: linesPerStep)
                }
                try? await Task.sleep(nanoseconds: stepNanos)
            }
        }
    }
}

// MARK: - Dead Session Overlay

private struct DeadSessionOverlay: View {
    let isDark: Bool
    let onRestart: () -> Void

    private var t: NookTheme { NookTheme(isDark: isDark) }
    @State private var isHovered = false

    var body: some View {
        ZStack {
            t.scrim.ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "terminal")
                    .font(NookType.heroL)
                    .foregroundStyle(t.iconFgMute)

                Text("Session ended")
                    .font(NookType.formValueEmph)
                    .foregroundStyle(t.fg)

                Button(action: onRestart) {
                    Text("Restart")
                        .font(NookType.body)
                        .foregroundStyle(t.fg)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                                .fill(isHovered ? t.pressedBg : t.hoverBg)
                        )
                }
                .buttonStyle(.plain)
                .onHover { isHovered = $0 }
                .animation(.easeOut(duration: 0.12), value: isHovered)
            }
        }
        .transition(.opacity.animation(.easeIn(duration: 0.15)))
    }
}
