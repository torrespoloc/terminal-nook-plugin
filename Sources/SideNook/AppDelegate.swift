// Sources/SideNook/AppDelegate.swift
import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    enum Constants {
        static let pillWidth: CGFloat = 6
        static let pillHeight: CGFloat = 120
        static let hitTestDepth: CGFloat = 20
    }

    private let state = NookState()
    private var panel: SideNookPanel!
    private var monitor: Any?
    private var moveObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard NSScreen.main != nil else { return }

        let pillSize = pillDimensions(for: state.dockedEdge)
        panel = SideNookPanel(
            contentRect: NSRect(origin: state.panelPosition, size: pillSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        let rootView = SideNookView(state: state)
        let hostingView = TrackingHostingView(
            rootView: rootView,
            onMouseExit: { [weak self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    guard let self else { return }
                    let mouse = NSEvent.mouseLocation
                    if !self.state.isPinned && !self.panel.frame.contains(mouse) {
                        self.collapse()
                    }
                }
            }
        )

        panel.onDragEnd = { [weak self] in
            self?.snapToNearestEdge()
        }
        panel.contentView = hostingView
        panel.ignoresMouseEvents = true
        panel.orderFrontRegardless()

        // Global mouse-move monitor for edge hit-test
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            guard let self else { return }
            let mouse = NSEvent.mouseLocation
            let hitRect = self.hitTestRect()
            if hitRect.contains(mouse) && !self.state.isExpanded {
                self.expand()
            }
        }

        // Track panel moves (drag) and snap to nearest edge
        moveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.state.isExpanded else { return }
                self.state.panelPosition = self.panel.frame.origin
            }
        }

        // Snap to edge after drag ends
        NotificationCenter.default.addObserver(
            forName: NSWindow.didEndLiveResizeNotification,
            object: panel,
            queue: .main
        ) { _ in }

        startObservingState()
    }

    // MARK: - State Observation

    private func startObservingState() {
        withObservationTracking {
            _ = state.isExpanded
            _ = state.isPinned
            _ = state.expandedSize
            _ = state.dockedEdge
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.applyStateChange()
                self?.startObservingState()
            }
        }
    }

    // MARK: - Expand / Collapse

    private func expand() {
        guard !state.isExpanded else { return }
        state.expand()
    }

    private func collapse() {
        guard state.isExpanded else { return }
        state.collapse()
    }

    // MARK: - Apply State Changes

    private func applyStateChange() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        // If unpinned while expanded, check if mouse is outside and collapse
        if state.isExpanded && !state.isPinned {
            let mouse = NSEvent.mouseLocation
            if !panel.frame.contains(mouse) {
                collapse()
                return
            }
        }

        if state.isExpanded {
            let size = NSSize(
                width: state.expandedSize.width,
                height: state.expandedSize.height
            )
            let pos = clampToScreen(
                origin: expandedOrigin(screenFrame: screenFrame),
                size: size,
                screenFrame: screenFrame
            )
            state.panelPosition = pos
            panel.setFrame(NSRect(origin: pos, size: size), display: true, animate: false)
            panel.ignoresMouseEvents = false
            panel.hasShadow = true
            panel.makeKey()
        } else {
            panel.resignKey()
            panel.hasShadow = false
            let pillSize = pillDimensions(for: state.dockedEdge)
            let pos = pillOrigin(screenFrame: screenFrame)
            state.panelPosition = pos
            panel.setFrame(NSRect(origin: pos, size: pillSize), display: true, animate: false)
            panel.ignoresMouseEvents = true
        }
    }

    // MARK: - Edge-Adaptive Geometry

    /// Pill dimensions depend on docked edge: tall+thin for left/right, wide+thin for top/bottom.
    private func pillDimensions(for edge: NookState.ScreenEdge) -> NSSize {
        switch edge {
        case .left, .right:
            return NSSize(width: Constants.pillWidth, height: Constants.pillHeight)
        case .top, .bottom:
            return NSSize(width: Constants.pillHeight, height: Constants.pillWidth)
        }
    }

    /// Where the pill sits when collapsed — snapped to the docked edge.
    private func pillOrigin(screenFrame: NSRect) -> CGPoint {
        let pos = state.panelPosition
        switch state.dockedEdge {
        case .left:
            return CGPoint(x: screenFrame.minX, y: pos.y)
        case .right:
            return CGPoint(x: screenFrame.maxX - Constants.pillWidth, y: pos.y)
        case .top:
            return CGPoint(x: pos.x, y: screenFrame.maxY - Constants.pillWidth)
        case .bottom:
            return CGPoint(x: pos.x, y: screenFrame.minY)
        }
    }

    /// Where the expanded container opens from — anchored to the docked edge.
    private func expandedOrigin(screenFrame: NSRect) -> CGPoint {
        let pos = state.panelPosition
        let w = state.expandedSize.width
        let h = state.expandedSize.height
        switch state.dockedEdge {
        case .left:
            return CGPoint(x: screenFrame.minX, y: pos.y)
        case .right:
            return CGPoint(x: screenFrame.maxX - w, y: pos.y)
        case .top:
            return CGPoint(x: pos.x, y: screenFrame.maxY - h)
        case .bottom:
            return CGPoint(x: pos.x, y: screenFrame.minY)
        }
    }

    /// The hit-test rect for the collapsed pill — a generous zone around the pill.
    private func hitTestRect() -> NSRect {
        let panelFrame = panel.frame
        let depth = Constants.hitTestDepth
        switch state.dockedEdge {
        case .left:
            return NSRect(x: panelFrame.minX, y: panelFrame.minY,
                          width: depth, height: panelFrame.height)
        case .right:
            return NSRect(x: panelFrame.maxX - depth, y: panelFrame.minY,
                          width: depth, height: panelFrame.height)
        case .top:
            return NSRect(x: panelFrame.minX, y: panelFrame.maxY - depth,
                          width: panelFrame.width, height: depth)
        case .bottom:
            return NSRect(x: panelFrame.minX, y: panelFrame.minY,
                          width: panelFrame.width, height: depth)
        }
    }

    // MARK: - Snap to Edge

    /// Called after a drag to detect and snap to the nearest edge.
    func snapToNearestEdge() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let panelFrame = panel.frame
        let center = CGPoint(
            x: panelFrame.midX,
            y: panelFrame.midY
        )
        let edge = nearestScreenEdge(panelCenter: center, screenFrame: screenFrame)
        state.dockedEdge = edge
    }

    // MARK: - Helpers

    private func clampToScreen(origin: CGPoint, size: NSSize, screenFrame: NSRect) -> CGPoint {
        let x = min(max(origin.x, screenFrame.minX), screenFrame.maxX - size.width)
        let y = min(max(origin.y, screenFrame.minY), screenFrame.maxY - size.height)
        return CGPoint(x: x, y: y)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor { NSEvent.removeMonitor(monitor) }
        if let moveObserver { NotificationCenter.default.removeObserver(moveObserver) }
        for session in state.sessions { session.terminate() }
    }
}
