// Sources/SideNook/AppDelegate.swift
import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    enum Constants {
        static let pillWidth: CGFloat = 6
        static let pillHeight: CGFloat = 120
        static let expandedWidth: CGFloat = 450
        static let expandedHeight: CGFloat = 600
        static let hitTestWidth: CGFloat = 20
    }

    private let state = NookState()
    private var panel: SideNookPanel!
    private var monitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame

        // Position the pill at the left edge, vertically centered
        let pillOrigin = NSPoint(
            x: screenFrame.minX,
            y: screenFrame.midY - Constants.pillHeight / 2
        )

        panel = SideNookPanel(
            contentRect: NSRect(
                origin: pillOrigin,
                size: NSSize(width: Constants.pillWidth, height: Constants.pillHeight)
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        let rootView = SideNookView(state: state)
        let hostingView = TrackingHostingView(
            rootView: rootView,
            onMouseExit: { [weak self] in
                self?.state.collapse()
            }
        )

        panel.contentView = hostingView
        panel.ignoresMouseEvents = true
        panel.orderFrontRegardless()

        // Global mouse-move monitor for hit-test region
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self else { return }
            let mouseLocation = NSEvent.mouseLocation
            let panelFrame = self.panel.frame

            let hitRect = NSRect(
                x: panelFrame.minX,
                y: panelFrame.minY,
                width: Constants.hitTestWidth,
                height: panelFrame.height
            )

            if hitRect.contains(mouseLocation) {
                if !self.state.isExpanded {
                    self.state.expand()
                }
            }
        }

        // Observe state changes and resize panel accordingly
        startObservingState()
    }

    private func startObservingState() {
        withObservationTracking {
            _ = state.isExpanded
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.applyStateChange()
                self?.startObservingState()
            }
        }
    }

    private func applyStateChange() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        if state.isExpanded {
            let origin = NSPoint(
                x: screenFrame.minX,
                y: screenFrame.midY - Constants.expandedHeight / 2
            )
            panel.setFrame(
                NSRect(origin: origin, size: NSSize(width: Constants.expandedWidth, height: Constants.expandedHeight)),
                display: true,
                animate: false
            )
            panel.ignoresMouseEvents = false
        } else {
            let origin = NSPoint(
                x: screenFrame.minX,
                y: screenFrame.midY - Constants.pillHeight / 2
            )
            panel.setFrame(
                NSRect(origin: origin, size: NSSize(width: Constants.pillWidth, height: Constants.pillHeight)),
                display: true,
                animate: false
            )
            panel.ignoresMouseEvents = true
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
