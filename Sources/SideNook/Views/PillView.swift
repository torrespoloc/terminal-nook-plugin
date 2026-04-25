// Sources/SideNook/Views/PillView.swift
import SwiftUI

/// Rest state — the thin edge indicator shown when the panel is collapsed.
/// Shows only the pill line and optional session status dot.
struct PillView: View {
    let state: NookState

    private static let fill   = Color(red: 0.039, green: 0.039, blue: 0.047, opacity: 0.94)
    private static let border  = Color.white.opacity(0.18)

    private var dotColor: Color? {
        let statuses = state.sessions.map(\.status)
        if statuses.contains(.attn) { return state.theme.dotAttn }
        if statuses.contains(.live) { return state.theme.dotLive }
        return nil
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 60, style: .continuous)
            .fill(Self.fill)
            .overlay {
                RoundedRectangle(cornerRadius: 60, style: .continuous)
                    .strokeBorder(Self.border, lineWidth: 0.5)
            }
            .overlay { statusDot }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 60, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [state.theme.innerHighlight, .clear],
                            startPoint: .top, endPoint: .center
                        ),
                        lineWidth: 0.5
                    )
                    .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(0.5), radius: 7, y: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var statusDot: some View {
        if let color = dotColor {
            let isVertical = state.dockedEdge == .left || state.dockedEdge == .right
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity,
                       alignment: isVertical ? .bottom : .trailing)
                .padding(isVertical ? .bottom : .trailing, 9)
        }
    }
}
