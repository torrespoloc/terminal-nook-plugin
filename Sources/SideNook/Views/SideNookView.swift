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
        state.isExpanded ? 14 : 60
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
                    color: Color.black.opacity(state.isDark ? 0.55 : 0.18),
                    radius: state.isExpanded ? 40 : 0,
                    y: state.isExpanded ? 12 : 0
                )
                .shadow(
                    color: Color.black.opacity(state.isDark ? 0.35 : 0.10),
                    radius: state.isExpanded ? 10 : 0,
                    y: state.isExpanded ? 2 : 0
                )

            // Expanded content
            if state.isExpanded, let session = state.activeSession {
                ZStack {
                    if state.tabLayout == .leftSidebar {
                        HStack(spacing: 8) {
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
