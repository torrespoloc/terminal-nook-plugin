// Sources/SideNook/Views/PillView.swift
import SwiftUI

/// Rest state — the thin edge indicator shown when the panel is collapsed.
/// Shape spec: 8×152 pill, 240pt corner radius on the side opposite the screen edge,
/// 0pt on the side touching the edge. Background black 96%, 1pt white 10% border.
struct PillView: View {
    let state: NookState
    @State private var pulse: Bool = false

    private static let fill   = Color.black.opacity(0.96)
    private static let border = Color.white.opacity(0.10)

    private var statusKind: (color: Color, isAttn: Bool) {
        let statuses = state.sessions.map(\.status)
        if statuses.contains(.attn) { return (state.theme.dotAttn, true) }
        if statuses.contains(.live) { return (state.theme.dotLive, false) }
        return (state.theme.dotIdle, false)
    }

    /// 240pt radius on the side opposite the docked edge; 0pt on the edge-facing side.
    private var radii: (tl: CGFloat, tr: CGFloat, bl: CGFloat, br: CGFloat) {
        let r: CGFloat = 240
        switch state.dockedEdge {
        case .right:  return (r, 0, r, 0)
        case .left:   return (0, r, 0, r)
        case .top:    return (0, 0, r, r)
        case .bottom: return (r, r, 0, 0)
        }
    }

    /// Intrinsic pill size — locked to the constants so the pill never stretches
    /// when the panel grows during the expand transition.
    private var pillSize: CGSize {
        let isVertical = state.dockedEdge == .left || state.dockedEdge == .right
        return isVertical
            ? CGSize(width: AppDelegate.Constants.pillWidth, height: AppDelegate.Constants.pillHeight)
            : CGSize(width: AppDelegate.Constants.pillHeight, height: AppDelegate.Constants.pillWidth)
    }

    /// Anchor the pill against its docked screen edge inside the parent frame.
    private var edgeAlignment: Alignment {
        switch state.dockedEdge {
        case .left:   return .leading
        case .right:  return .trailing
        case .top:    return .top
        case .bottom: return .bottom
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
            .overlay { shape.strokeBorder(Self.border, lineWidth: 1) }
            .overlay { statusDot }

            .frame(width: pillSize.width, height: pillSize.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: edgeAlignment)
    }

    @ViewBuilder
    private var statusDot: some View {
        let kind = statusKind
        let isVertical = state.dockedEdge == .left || state.dockedEdge == .right
        // Stripe runs along the pill's long axis: 6pt across × 16pt along.
        let w: CGFloat = isVertical ? 6 : 16
        let h: CGFloat = isVertical ? 16 : 6
        Capsule()
            .fill(kind.color)
            .frame(width: w, height: h)
            .opacity(kind.isAttn && pulse ? 0.35 : 1)
            .animation(
                kind.isAttn
                    ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true)
                    : .default,
                value: pulse
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity,
                   alignment: isVertical ? .bottom : .trailing)
            .padding(isVertical ? .bottom : .trailing, 6)
            .onAppear { if kind.isAttn { pulse = true } }
            .onChange(of: kind.isAttn) { _, attn in pulse = attn }
    }
}
