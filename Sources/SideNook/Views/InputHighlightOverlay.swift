// Sources/SideNook/Views/InputHighlightOverlay.swift
import AppKit
import SwiftUI
import SwiftTerm

// MARK: - NSView

/// Transparent overlay drawn on top of the terminal. Paints a subtle baby-blue band
/// behind each row where the user submitted input. Reads terminal scroll state live
/// at draw time so highlights stay correct during scrolling.
@MainActor
final class InputHighlightOverlay: NSView {

    var absRows: [Int] = [] {
        didSet {
            needsDisplay = true
            updateScrollWatcher()
        }
    }
    var isDark: Bool = true { didSet { needsDisplay = true } }

    /// Direct reference to the terminal — used to read live yDisp and rows in draw.
    weak var terminal: LocalProcessTerminalView? {
        didSet { updateScrollWatcher() }
    }

    // nonisolated(unsafe) so deinit can call invalidate() without actor-isolation errors.
    // All writes happen on the main thread; deinit on NSView is also main-thread.
    nonisolated(unsafe) private var scrollWatcher: Timer?
    private var lastKnownYDisp: Int = -1

    /// Polls at 30 fps while there are rows to highlight, marking dirty only when
    /// yDisp changes (i.e. the user is actively scrolling).
    private func updateScrollWatcher() {
        scrollWatcher?.invalidate()
        scrollWatcher = nil
        guard terminal != nil, !absRows.isEmpty else { return }
        // Timer scheduled on RunLoop.main fires on the main thread.
        scrollWatcher = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            // assumeIsolated is safe: timer fires on RunLoop.main == main actor executor.
            MainActor.assumeIsolated {
                guard let term = self.terminal?.getTerminal() else { return }
                let yDisp = term.buffer.yDisp
                if yDisp != self.lastKnownYDisp {
                    self.lastKnownYDisp = yDisp
                    self.needsDisplay = true
                }
            }
        }
    }

    deinit { scrollWatcher?.invalidate() }

    override var isFlipped: Bool { true }

    /// Pass all mouse events through to the terminal below.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func draw(_ dirtyRect: NSRect) {
        guard !absRows.isEmpty,
              let term = terminal?.getTerminal() else { return }
        let rows = term.rows
        guard rows > 0 else { return }
        let yDisp = term.buffer.yDisp
        let cellH = bounds.height / CGFloat(rows)
        let color: NSColor = isDark
            ? NSColor(red: 0.53, green: 0.73, blue: 0.95, alpha: 0.14)
            : NSColor(red: 0.25, green: 0.55, blue: 0.88, alpha: 0.10)

        for absRow in absRows {
            let viewportRow = absRow - yDisp
            guard viewportRow >= 0, viewportRow < rows else { continue }
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

    func makeNSView(context: Context) -> InputHighlightOverlay {
        InputHighlightOverlay()
    }

    func updateNSView(_ nsView: InputHighlightOverlay, context: Context) {
        nsView.terminal = session.terminalView
        nsView.absRows = session.inputHighlightRows
        nsView.isDark = isDark
    }
}
