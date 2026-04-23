// Sources/SideNook/Terminal/TerminalView.swift
import SwiftUI
import SwiftTerm

/// SwiftUI wrapper that displays a pre-created LocalProcessTerminalView
/// from a TerminalSession. The session owns the terminal view and its PTY,
/// so terminal state survives tab switches. SwiftUI manages the NSView frame.
struct TerminalSessionView: NSViewRepresentable {
    let session: TerminalSession

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        session.terminalView
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
        // SwiftUI's layout engine sets the NSView frame, which triggers
        // SwiftTerm's setFrameSize → PTY resize. No manual sizing needed.
    }
}
