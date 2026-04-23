// Sources/SideNook/Terminal/TerminalView.swift
import SwiftUI
import SwiftTerm

/// SwiftUI wrapper that displays a pre-created LocalProcessTerminalView
/// from a TerminalSession. The session owns the terminal view and its PTY,
/// so terminal state survives tab switches.
struct TerminalSessionView: NSViewRepresentable {
    let session: TerminalSession
    let containerSize: CGSize

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        session.terminalView
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
        guard nsView.frame.size != containerSize else { return }
        nsView.frame.size = containerSize
        nsView.needsLayout = true
    }
}
