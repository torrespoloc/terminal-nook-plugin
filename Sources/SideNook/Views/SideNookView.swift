// Sources/SideNook/Views/SideNookView.swift
import SwiftUI

struct SideNookView: View {
    @Bindable var state: NookState

    // Pill is always dark regardless of mode
    private static let pillFill = Color.black.opacity(0.96)
    private static let pillBorder = Color.white.opacity(0.12)

    // Appearance-adaptive colors (expanded only)
    private var fillColor: Color {
        state.isExpanded
            ? (state.isDark ? Color.black.opacity(0.96) : Color(white: 0.965))
            : Self.pillFill
    }
    private var borderColor: Color {
        state.isExpanded
            ? (state.isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.10))
            : Self.pillBorder
    }

    private var outerRadius: CGFloat {
        state.isExpanded ? 16 : 60
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
                .shadow(
                    color: state.isExpanded
                        ? Color.black.opacity(state.isDark ? 0.5 : 0.15)
                        : Color.clear,
                    radius: state.isExpanded ? 20 : 0,
                    y: state.isExpanded ? 4 : 0
                )

            // Expanded content
            if state.isExpanded, let session = state.activeSession {
                ZStack {
                    VStack(spacing: 0) {
                        NavBarView(state: state)

                        TerminalContainerView(session: session, isDark: state.isDark)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 8)
                    }

                    // About overlay
                    if state.showAbout {
                        Color.black.opacity(0.4)
                            .onTapGesture { state.showAbout = false }

                        AboutView(isDark: state.isDark) {
                            state.showAbout = false
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: Color.black.opacity(0.3), radius: 16, y: 4)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: outerRadius, style: .continuous))
                .transition(.opacity.animation(.easeIn(duration: 0.12)))
                .animation(.easeOut(duration: 0.2), value: state.showAbout)

                resizeHandles
            }
        }
        // Fill the NSPanel — no explicit frame sizing, no spring animation.
        // The NSPanel frame is the single source of truth for dimensions.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
