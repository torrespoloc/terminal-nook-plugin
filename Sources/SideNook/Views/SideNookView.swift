// Sources/SideNook/Views/SideNookView.swift
import SwiftUI

struct SideNookView: View {
    @Bindable var state: NookState

    // Pill is always dark regardless of mode
    private static let pillFill = Color(red: 0.039, green: 0.039, blue: 0.047, opacity: 0.94)
    private static let pillBorder = Color.white.opacity(0.18)

    private var t: NookTheme { state.theme }

    // Appearance-adaptive colors (expanded only)
    private var fillColor: Color {
        state.isExpanded ? t.L0 : Self.pillFill
    }
    private var borderColor: Color {
        state.isExpanded ? t.stroke0 : Self.pillBorder
    }

    private var outerRadius: CGFloat {
        state.isExpanded ? 14 : 60
    }

    private var pillStatusColor: Color? {
        guard !state.isExpanded else { return nil }
        let statuses = state.sessions.map(\.status)
        if statuses.contains(.attn) { return state.theme.dotAttn }
        if statuses.contains(.live) { return state.theme.dotLive }
        return nil
    }

    var body: some View {
        ZStack {
            // Background shell — always present
            RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                .fill(fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 0.5)
                )
                .overlay {
                    if let dotColor = pillStatusColor {
                        pillStatusDot(color: dotColor)
                    }
                }
                .overlay(alignment: .top) {
                    // Top inner highlight — simulates glass edge
                    RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [state.theme.innerHighlight, .clear],
                                startPoint: .top, endPoint: .center
                            ),
                            lineWidth: 0.5
                        )
                        .allowsHitTesting(false)
                }
                .shadow(
                    color: Color.black.opacity(state.isExpanded ? (state.isDark ? 0.55 : 0.18) : 0.5),
                    radius: state.isExpanded ? (state.isDark ? 25 : 20) : 7,
                    y: state.isExpanded ? (state.isDark ? 18 : 14) : 4
                )
                .shadow(
                    color: Color.black.opacity(state.isExpanded ? (state.isDark ? 0.35 : 0.10) : 0),
                    radius: state.isExpanded ? (state.isDark ? 6 : 5) : 0,
                    y: state.isExpanded ? (state.isDark ? 4 : 3) : 0
                )

            // Expanded content
            if state.isExpanded, let session = state.activeSession {
                ZStack {
                    if state.tabLayout == .leftSidebar {
                        HStack(spacing: 6) {
                            SidebarNavView(state: state)
                                .padding(.leading, 8)
                                .padding(.vertical, 8)
                            TerminalContainerView(session: session, isDark: state.isDark)
                                .padding(.trailing, 8)
                                .padding(.vertical, 8)
                        }
                    } else {
                        VStack(spacing: 0) {
                            NavBarView(state: state)
                            TerminalContainerView(session: session, isDark: state.isDark)
                                .padding(.horizontal, 8)
                                .padding(.bottom, 8)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: outerRadius, style: .continuous))
                .transition(.opacity.animation(.easeIn(duration: 0.12)))

                resizeHandles
            }
        }
        // Fill the NSPanel — no explicit frame sizing, no spring animation.
        // The NSPanel frame is the single source of truth for dimensions.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func pillStatusDot(color: Color) -> some View {
        let isVertical = state.dockedEdge == .left || state.dockedEdge == .right
        if isVertical {
            // Pill is tall — status dot sits at the bottom, horizontally centered
            Circle().fill(color).frame(width: 5, height: 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 9)
        } else {
            // Pill is wide — status dot sits at the trailing end, vertically centered
            Circle().fill(color).frame(width: 5, height: 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .padding(.trailing, 9)
        }
    }

    @ViewBuilder
    private var resizeHandles: some View {
        let edge = state.dockedEdge
        if edge != .right {
            HStack {
                Spacer()
                ResizeHandleView(edge: .right, state: state)
                    .frame(width: 12)
            }
        }
        if edge != .top {
            VStack {
                Spacer()
                ResizeHandleView(edge: .bottom, state: state)
                    .frame(height: 12)
            }
        }
        if edge != .bottom {
            VStack {
                ResizeHandleView(edge: .top, state: state)
                    .frame(height: 12)
                Spacer()
            }
        }
        if edge != .left {
            HStack {
                ResizeHandleView(edge: .left, state: state)
                    .frame(width: 12)
                Spacer()
            }
        }
    }
}
