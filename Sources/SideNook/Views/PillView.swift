// Sources/SideNook/Views/PillView.swift
import SwiftUI

/// Rest state — the thin edge indicator shown when the panel is collapsed.
/// Shape spec: 4×38 pill, 60pt corner radius on the side opposite the screen edge,
/// 0pt on the side touching the edge. Background black 96%, 0.5pt white 10% border.
struct PillView: View {
    let state: NookState

    private static let fill   = Color.black.opacity(0.96)
    private static let border = Color.white.opacity(0.10)

    private var dotColor: Color? {
        let statuses = state.sessions.map(\.status)
        if statuses.contains(.attn) { return state.theme.dotAttn }
        if statuses.contains(.live) { return state.theme.dotLive }
        return nil
    }

    /// 60pt radius on the side opposite the docked edge; 0pt on the edge-facing side.
    private var radii: (tl: CGFloat, tr: CGFloat, bl: CGFloat, br: CGFloat) {
        let r: CGFloat = 60
        switch state.dockedEdge {
        case .right:  return (r, 0, r, 0)
        case .left:   return (0, r, 0, r)
        case .top:    return (0, 0, r, r)
        case .bottom: return (r, r, 0, 0)
        }
    }

    var body: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: radii.tl,
            bottomLeadingRadius: radii.bl,
            bottomTrailingRadius: radii.br,
            topTrailingRadius: radii.tr,
            style: .continuous
        )

        shape
            .fill(Self.fill)
            .overlay { shape.strokeBorder(Self.border, lineWidth: 0.5) }
            .overlay { statusDot }
            .shadow(color: .black.opacity(0.5), radius: 7, y: 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var statusDot: some View {
        if let color = dotColor {
            let isVertical = state.dockedEdge == .left || state.dockedEdge == .right
            Circle()
                .fill(color)
                .frame(width: 2, height: 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity,
                       alignment: isVertical ? .bottom : .trailing)
                .padding(isVertical ? .bottom : .trailing, 3)
        }
    }
}
