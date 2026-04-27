// Sources/SideNook/Views/ExpandedView.swift
import SwiftUI

/// Expanded state — the full panel UI with background, content, and resize handles as one unit.
/// Background and content are always rendered together; there is no intermediate empty-shell state.
struct ExpandedView: View {
    @Bindable var state: NookState

    private var t: NookTheme { state.theme }

    var body: some View {
        ZStack {
            background
            if let session = state.activeSession {
                panelContent(session: session)
            }
            resizeHandles
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Background

    private var background: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(t.L0)
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(t.stroke0, lineWidth: 0.5)
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [t.innerHighlight, .clear],
                            startPoint: .top, endPoint: .center
                        ),
                        lineWidth: 0.5
                    )
                    .allowsHitTesting(false)
            }
            .shadow(
                color: .black.opacity(t.isDark ? 0.55 : 0.18),
                radius: t.isDark ? 25 : 20,
                y: t.isDark ? 18 : 14
            )
            .shadow(
                color: .black.opacity(t.isDark ? 0.35 : 0.10),
                radius: t.isDark ? 6 : 5,
                y: t.isDark ? 4 : 3
            )
    }

    // MARK: - Content

    @ViewBuilder
    private func panelContent(session: TerminalSession) -> some View {
        Group {
            if state.tabLayout == .leftSidebar {
                HStack(spacing: 6) {
                    SidebarNavView(state: state)
                        .padding(.leading, 8)
                        .padding(.vertical, 8)
                    TerminalContainerView(session: session, isDark: state.isDark)
                        .padding(.trailing, 8)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }
            } else {
                VStack(spacing: 0) {
                    NavBarView(state: state)
                    TerminalContainerView(session: session, isDark: state.isDark)
                        .padding(.horizontal, 8)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Resize Handles

    @ViewBuilder
    private var resizeHandles: some View {
        let edge = state.dockedEdge
        if edge != .right {
            HStack { Spacer(); ResizeHandleView(edge: .right, state: state).frame(width: 12) }
        }
        if edge != .bottom {
            VStack { Spacer(); ResizeHandleView(edge: .bottom, state: state).frame(height: 12) }
        }
        if edge != .top {
            VStack { ResizeHandleView(edge: .top, state: state).frame(height: 12); Spacer() }
        }
        if edge != .left {
            HStack { ResizeHandleView(edge: .left, state: state).frame(width: 12); Spacer() }
        }
    }
}
