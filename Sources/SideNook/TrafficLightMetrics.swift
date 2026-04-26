// Sources/SideNook/TrafficLightMetrics.swift
import AppKit

/// Runtime geometry for the three traffic light buttons, probed from a hidden
/// off-screen NSWindow so values stay correct across macOS releases.
@MainActor
struct TrafficLightMetrics {
    static let shared = TrafficLightMetrics()

    /// Diameter of each circular button.
    let diameter: CGFloat
    /// Center-to-center horizontal spacing between adjacent buttons.
    let centerSpacing: CGFloat
    /// Distance from the left edge of the window frame to the close button center.
    let leadingInset: CGFloat
    /// Distance from the top of the window frame to the button centers.
    let topInset: CGFloat

    private init() {
        if let m = Self.probe() {
            diameter      = m.diameter
            centerSpacing = m.centerSpacing
            leadingInset  = m.leadingInset
            topInset      = m.topInset
        } else {
            // Hardcoded fallback — matches Sequoia/Sonoma values.
            diameter      = 12
            centerSpacing = 20
            leadingInset  = 8
            topInset      = 8
        }
    }

    // MARK: - Probe

    private static func probe() -> (diameter: CGFloat, centerSpacing: CGFloat,
                                    leadingInset: CGFloat, topInset: CGFloat)? {
        // Create a titled window far off-screen. defer: true avoids allocating
        // window-server resources while still giving us correct button frames.
        let win = NSWindow(
            contentRect: NSRect(x: -10_000, y: -10_000, width: 300, height: 200),
            styleMask:   [.titled, .closable, .miniaturizable, .resizable],
            backing:     .buffered,
            defer:       true
        )

        guard
            let close    = win.standardWindowButton(.closeButton),
            let minimize = win.standardWindowButton(.miniaturizeButton),
            let superview = close.superview
        else { return nil }

        let diameter = close.frame.width
        guard diameter > 0 else { return nil }

        // Spacing is purely horizontal in the shared superview — no conversion needed.
        let centerSpacing = minimize.frame.midX - close.frame.midX

        // Convert close-button center → screen coordinates → window-relative coordinates.
        // AppKit uses bottom-left origin, so topInset counts down from the window top.
        let centerInSuper  = CGPoint(x: close.frame.midX, y: close.frame.midY)
        let centerInScreen = superview.convert(centerInSuper, to: nil)
        let winOrigin      = win.frame.origin

        let cx = centerInScreen.x - winOrigin.x
        let cy = centerInScreen.y - winOrigin.y

        let leadingInset = cx
        let topInset     = win.frame.height - cy

        guard centerSpacing > 0, leadingInset > 0, topInset > 0 else { return nil }

        return (diameter, centerSpacing, leadingInset, topInset)
    }
}
