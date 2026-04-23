// Sources/SideNook/Views/InputHighlightOverlay.swift
import AppKit
import SwiftUI
import SwiftTerm

// MARK: - NSView

/// Transparent overlay drawn on top of the terminal. Paints a subtle baby-blue band
/// behind each row where the user submitted input.
@MainActor
final class InputHighlightOverlay: NSView {

    /// Absolute buffer row indices (yDisp + buffer.y at time of input).
    var absRows: [Int] = [] { didSet { needsDisplay = true } }
    var terminalRows: Int = 24 { didSet { needsDisplay = true } }
    var yDisp: Int = 0 { didSet { needsDisplay = true } }
    var isDark: Bool = true { didSet { needsDisplay = true } }

    override var isFlipped: Bool { true }

    /// Pass all mouse events through to the terminal below.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func draw(_ dirtyRect: NSRect) {
        guard !absRows.isEmpty, terminalRows > 0 else { return }
        let cellH = bounds.height / CGFloat(terminalRows)
        let color: NSColor = isDark
            ? NSColor(red: 0.53, green: 0.73, blue: 0.95, alpha: 0.14)
            : NSColor(red: 0.25, green: 0.55, blue: 0.88, alpha: 0.10)

        for absRow in absRows {
            let viewportRow = absRow - yDisp
            guard viewportRow >= 0, viewportRow < terminalRows else { continue }
            let rect = NSRect(x: 0,
                              y: CGFloat(viewportRow) * cellH,
                              width: bounds.width,
                              height: cellH)
            guard rect.intersects(dirtyRect) else { continue }
            color.setFill()
            rect.fill()
        }
    }
}

// MARK: - SwiftUI wrapper

struct InputHighlightView: NSViewRepresentable {
    let session: TerminalSession
    let isDark: Bool
    let containerSize: CGSize

    func makeNSView(context: Context) -> InputHighlightOverlay {
        InputHighlightOverlay()
    }

    func updateNSView(_ nsView: InputHighlightOverlay, context: Context) {
        let term = session.terminalView.getTerminal()
        nsView.absRows = session.inputHighlightRows
        nsView.terminalRows = term.rows
        nsView.yDisp = term.buffer.yDisp
        nsView.isDark = isDark
        nsView.frame.size = containerSize
    }
}
