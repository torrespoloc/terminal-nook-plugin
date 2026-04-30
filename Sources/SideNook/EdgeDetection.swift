// Sources/SideNook/EdgeDetection.swift
import AppKit

/// Determines the nearest screen edge for the given panel frame.
/// Uses the panel's near edge (not center) so that a panel touching the left
/// edge at x:0 always resolves to .left even when the top edge is closer to
/// the panel center — this gives correct quadrant-corner behaviour.
@MainActor
func nearestScreenEdge(panelFrame: NSRect, screenFrame: NSRect) -> NookState.ScreenEdge {
    let distLeft   = panelFrame.minX - screenFrame.minX
    let distRight  = screenFrame.maxX - panelFrame.maxX
    let distBottom = panelFrame.minY - screenFrame.minY
    let distTop    = screenFrame.maxY - panelFrame.maxY

    let minDist = min(distLeft, distRight, distBottom, distTop)

    if minDist == distLeft   { return .left }
    if minDist == distRight  { return .right }
    if minDist == distTop    { return .top }
    return .bottom
}

/// Snaps the panel origin to the nearest screen edge, keeping the
/// position along the edge (vertical for left/right, horizontal for top/bottom).
@MainActor
func snappedPosition(
    edge: NookState.ScreenEdge,
    panelOrigin: CGPoint,
    panelSize: NSSize,
    screenFrame: NSRect
) -> CGPoint {
    switch edge {
    case .left:
        return CGPoint(x: screenFrame.minX, y: panelOrigin.y)
    case .right:
        return CGPoint(x: screenFrame.maxX - panelSize.width, y: panelOrigin.y)
    case .top:
        return CGPoint(x: panelOrigin.x, y: screenFrame.maxY - panelSize.height)
    case .bottom:
        return CGPoint(x: panelOrigin.x, y: screenFrame.minY)
    }
}
