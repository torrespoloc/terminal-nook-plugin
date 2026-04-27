// Sources/SideNook/Views/ResizeHandleView.swift
import SwiftUI
import AppKit

enum ResizeEdge {
    case right, bottom, left, top
}

/// Invisible resize handle placed on the edge of the expanded container.
struct ResizeHandleView: NSViewRepresentable {
    let edge: ResizeEdge
    @Bindable var state: NookState

    func makeNSView(context: Context) -> ResizeHandleNSView {
        let view = ResizeHandleNSView()
        view.edge = edge
        view.state = state
        return view
    }

    func updateNSView(_ nsView: ResizeHandleNSView, context: Context) {
        nsView.edge = edge
        nsView.state = state
        nsView.window?.invalidateCursorRects(for: nsView)
    }
}

@MainActor
final class ResizeHandleNSView: NSView {
    var edge: ResizeEdge = .right
    var state: NookState?
    private var dragStartPoint: NSPoint?
    private var dragStartSize: CGSize?
    private var dragStartOrigin: CGPoint?

    override func resetCursorRects() {
        discardCursorRects()
        switch edge {
        case .left, .right:
            addCursorRect(bounds, cursor: .resizeLeftRight)
        case .top, .bottom:
            addCursorRect(bounds, cursor: .resizeUpDown)
        }
    }

    override var mouseDownCanMoveWindow: Bool { false }

    override func mouseDown(with event: NSEvent) {
        dragStartPoint = NSEvent.mouseLocation
        dragStartSize = state?.expandedSize
        dragStartOrigin = window?.frame.origin
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let state, let startPt = dragStartPoint,
              let startSize = dragStartSize,
              let startOrigin = dragStartOrigin,
              let window else { return }

        let currentPt = NSEvent.mouseLocation
        let dx = currentPt.x - startPt.x
        let dy = currentPt.y - startPt.y

        var newWidth = startSize.width
        var newHeight = startSize.height
        var newOriginX = startOrigin.x
        var newOriginY = startOrigin.y

        switch edge {
        case .right:
            newWidth = startSize.width + dx
        case .left:
            newWidth = startSize.width - dx
            newOriginX = startOrigin.x + dx
        case .bottom:
            // In macOS coords, bottom means lower y = subtract dy
            newHeight = startSize.height - dy
            newOriginY = startOrigin.y + dy
        case .top:
            newHeight = startSize.height + dy
        }

        // Clamp
        newWidth = min(max(newWidth, NookState.minExpandedSize.width), NookState.maxExpandedSize.width)
        newHeight = min(max(newHeight, NookState.minExpandedSize.height), NookState.maxExpandedSize.height)

        // Recompute origin if clamped
        if edge == .left {
            newOriginX = startOrigin.x + (startSize.width - newWidth)
        }
        if edge == .bottom {
            newOriginY = startOrigin.y + (startSize.height - newHeight)
        }

        state.expandedSize = CGSize(width: newWidth, height: newHeight)
        state.panelPosition = CGPoint(x: newOriginX, y: newOriginY)
        window.setFrame(
            NSRect(origin: CGPoint(x: newOriginX, y: newOriginY),
                   size: NSSize(width: newWidth, height: newHeight)),
            display: true,
            animate: false
        )
        super.mouseDragged(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        dragStartPoint = nil
        dragStartSize = nil
        dragStartOrigin = nil
        super.mouseUp(with: event)
    }
}
