// Sources/SideNook/Views/SideNookView.swift
import SwiftUI

struct SideNookView: View {
    @Bindable var state: NookState

    var body: some View {
        nook
            .animation(
                .interpolatingSpring(stiffness: 280, damping: 22),
                value: state.isExpanded
            )
    }

    // Pill dims depend on docked edge
    private var pillWidth: CGFloat {
        state.isVerticalEdge ? 6 : 120
    }
    private var pillHeight: CGFloat {
        state.isVerticalEdge ? 120 : 6
    }

    private var nook: some View {
        let w = state.isExpanded ? state.expandedSize.width : pillWidth
        let h = state.isExpanded ? state.expandedSize.height : pillHeight
        let radius: CGFloat = state.isExpanded ? 22 : 60

        return ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color.black.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
                )

            if state.isExpanded, let session = state.activeSession {
                VStack(spacing: 0) {
                    NavBarView(state: state)
                    TerminalContainerView(session: session)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                }
                .transition(.opacity.animation(.easeIn(duration: 0.08)))

                // Resize handles on non-docked edges
                resizeHandles
            }
        }
        .frame(width: w, height: h)
        .allowsHitTesting(state.isExpanded)
    }

    @ViewBuilder
    private var resizeHandles: some View {
        let edge = state.dockedEdge
        // Show handles on all edges except the one docked to the screen
        if edge != .right {
            HStack {
                Spacer()
                ResizeHandleView(edge: .right, state: state)
                    .frame(width: 6)
            }
        }
        if edge != .top {
            VStack {
                Spacer()
                ResizeHandleView(edge: .bottom, state: state)
                    .frame(height: 6)
            }
        }
        if edge != .bottom {
            VStack {
                ResizeHandleView(edge: .top, state: state)
                    .frame(height: 6)
                Spacer()
            }
        }
        if edge != .left {
            HStack {
                ResizeHandleView(edge: .left, state: state)
                    .frame(width: 6)
                Spacer()
            }
        }
    }
}
