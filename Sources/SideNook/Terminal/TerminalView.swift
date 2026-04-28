// Sources/SideNook/Terminal/TerminalView.swift
import SwiftUI
import SwiftTerm
import AppKit

@MainActor private func slimScroller(in view: NSView) {
    guard let scroller = view.subviews.first(where: { $0 is NSScroller }) as? NSScroller else { return }
    scroller.controlSize = .mini
    // Deactivate SwiftTerm's regular-width constraint and replace with a slim one.
    scroller.constraints
        .filter { $0.firstAttribute == .width && $0.secondAttribute == .notAnAttribute }
        .forEach { $0.isActive = false }
    scroller.widthAnchor.constraint(equalToConstant: 8).isActive = true
}

/// SwiftUI wrapper around a TerminalSession's LocalProcessTerminalView.
/// The session owns the PTY view so state survives tab switches.
/// A thin TerminalWrapperView sits between SwiftUI and SwiftTerm to:
///   - Return mouseDownCanMoveWindow = false (fixes three-finger-drag moving the window)
///   - Serve as the autoresizing container SwiftUI lays out
///   - Fire onFirstLayout so the PTY starts with correct terminal dimensions
struct TerminalSessionView: NSViewRepresentable {
    let session: TerminalSession

    func makeNSView(context: Context) -> TerminalWrapperView {
        let wrapper = TerminalWrapperView()
        wrapper.addSubview(session.terminalView)
        slimScroller(in: session.terminalView)
        wrapper.onFirstLayout = { [session] in
            session.startProcessIfNeeded()
        }
        return wrapper
    }

    func updateNSView(_ nsView: TerminalWrapperView, context: Context) {
        guard session.terminalView.superview !== nsView else { return }
        // Session view moved to a new wrapper (e.g. tab switch recreated the hierarchy)
        session.terminalView.removeFromSuperview()
        session.terminalView.frame = nsView.bounds
        nsView.addSubview(session.terminalView)
        nsView.needsLayout = true
    }
}

/// Transparent container that blocks window-move hit-testing on the terminal area.
/// Without this, isMovableByWindowBackground = true on the panel would capture
/// three-finger trackpad drags (and regular drags) as window moves instead of
/// delivering them to SwiftTerm for text selection.
final class TerminalWrapperView: NSView {
    override var mouseDownCanMoveWindow: Bool { false }
    override var isOpaque: Bool { false }

    var onFirstLayout: (() -> Void)?
    private var hasCalledFirstLayout = false

    override func layout() {
        // Size subviews to our bounds BEFORE calling super so that SwiftTerm's
        // own layout() override sees the correct frame and can calculate cols/rows
        // for TIOCSWINSZ. Relying on resizeSubviews(withOldSize:) is unreliable
        // because setting .frame directly doesn't trigger the subview's layout cycle.
        let b = bounds
        subviews.forEach { if $0.frame != b { $0.frame = b } }
        super.layout()

        // Start the PTY process once — after the first real layout gives us a valid size
        if !hasCalledFirstLayout && b.width > 0 && b.height > 0 {
            hasCalledFirstLayout = true
            onFirstLayout?()
        }
    }
}
