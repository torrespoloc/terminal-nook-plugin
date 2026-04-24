// Sources/SideNook/Terminal/TerminalView.swift
import SwiftUI
import SwiftTerm
import AppKit

/// SwiftUI wrapper around a TerminalSession's LocalProcessTerminalView.
/// The session owns the PTY view so state survives tab switches.
/// A thin TerminalWrapperView sits between SwiftUI and SwiftTerm to:
///   - Return mouseDownCanMoveWindow = false (fixes three-finger-drag moving the window)
///   - Serve as the autoresizing container SwiftUI lays out
struct TerminalSessionView: NSViewRepresentable {
    let session: TerminalSession

    func makeNSView(context: Context) -> TerminalWrapperView {
        let wrapper = TerminalWrapperView()
        wrapper.addSubview(session.terminalView)
        return wrapper
    }

    func updateNSView(_ nsView: TerminalWrapperView, context: Context) {
        if session.terminalView.superview !== nsView {
            session.terminalView.frame = nsView.bounds
            nsView.addSubview(session.terminalView)
        }
    }
}

/// Transparent container that blocks window-move hit-testing on the terminal area.
/// Without this, isMovableByWindowBackground = true on the panel would capture
/// three-finger trackpad drags (and regular drags) as window moves instead of
/// delivering them to SwiftTerm for text selection.
final class TerminalWrapperView: NSView {
    override var mouseDownCanMoveWindow: Bool { false }
    override var isOpaque: Bool { false }

    // Always fill the single subview to our bounds.
    // Autoresizing masks fail when the subview's initial size differs from
    // the wrapper's initial size (0×0 from SwiftUI layout), so we override
    // resize explicitly instead.
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        subviews.forEach { $0.frame = bounds }
    }
}
