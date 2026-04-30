// Sources/SideNook/LaunchSplashController.swift
import AppKit
import SwiftUI

/// Full-screen, transparent overlay shown once at cold launch.
/// Hosts `LaunchSplashView` (centered logo) for a fixed duration, then
/// invokes the completion handler so `AppDelegate` can reveal the pill.
@MainActor
final class LaunchSplashController {

    enum Constants {
        /// Total on-screen duration before dismissal. Matches the choreography
        /// in `LaunchSplashView` (slide → morph → hold → fade).
        static let duration: TimeInterval = 0.85
        /// Shorter duration when `accessibilityDisplayShouldReduceMotion` is on.
        static let reducedMotionDuration: TimeInterval = 0.50
    }

    private var panel: NSPanel?

    func present(on screen: NSScreen, completion: @escaping () -> Void) {
        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = true
        panel.isMovable = false

        let host = NSHostingView(rootView: LaunchSplashView())
        host.frame = NSRect(origin: .zero, size: screen.frame.size)
        host.autoresizingMask = [.width, .height]
        panel.contentView = host

        panel.setFrame(screen.frame, display: true, animate: false)
        panel.orderFrontRegardless()
        self.panel = panel

        let activeDuration = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            ? Constants.reducedMotionDuration
            : Constants.duration

        DispatchQueue.main.asyncAfter(deadline: .now() + activeDuration) { [weak self] in
            self?.dismiss()
            completion()
        }
    }

    private func dismiss() {
        panel?.orderOut(nil)
        panel = nil
    }
}
