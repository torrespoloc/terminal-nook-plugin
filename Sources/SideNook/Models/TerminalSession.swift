// Sources/SideNook/Models/TerminalSession.swift
import AppKit
import Observation
import SwiftTerm

@MainActor
@Observable
final class TerminalSession: Identifiable {
    let id = UUID()
    var title: String
    var isAlive: Bool = true
    var status: NookState.SessionStatus = .idle
    private(set) var hasTyped: Bool = false
    let screenName: String
    let isExternal: Bool = false

    let terminalView: SideNookTerminalView
    private let coordinator: SessionCoordinator
    private(set) var processStarted = false
    private var currentAppearance: NookState.Appearance = .dark

    /// Last known working directory — updated by the shell via OSC 7.
    /// Persisted on quit and used to restore the session on next launch.
    var currentDirectory: String?

    /// When set before `startProcessIfNeeded()`, the shell will `cd` here
    /// after it starts. Consumed on first use.
    var restoreDirectory: String?

    // MARK: - ANSI Color Palettes (matching Terminal.app)

    private static func c(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> SwiftTerm.Color {
        SwiftTerm.Color(red: r * 257, green: g * 257, blue: b * 257)
    }

    /// Dark mode palette — matches macOS Terminal.app "Basic" profile.
    /// Blues (index 4, 12) are lightened from the original so they remain readable
    /// when highlighted against the dark selection background.
    private static let darkPalette: [SwiftTerm.Color] = [
        c(0,   0,   0),     c(194, 54,  33),    c(37,  188, 36),    c(173, 173, 39),
        c(100, 140, 255),   c(211, 56,  211),   c(51,  187, 200),   c(203, 204, 205),
        c(129, 131, 131),   c(252, 57,  31),    c(49,  231, 34),    c(234, 236, 35),
        c(130, 180, 255),   c(249, 53,  248),   c(20,  240, 240),   c(233, 235, 235),
    ]

    /// Light mode palette — desaturated for readability on light backgrounds
    private static let lightPalette: [SwiftTerm.Color] = [
        c(0,   0,   0),     c(194, 54,  33),    c(38,  162, 38),    c(162, 152, 10),
        c(18,  72,  202),   c(163, 52,  163),   c(32,  156, 168),   c(218, 218, 218),
        c(118, 118, 118),   c(222, 56,  43),    c(57,  181, 57),    c(196, 186, 32),
        c(63,  90,  233),   c(204, 62,  204),   c(42,  186, 196),   c(240, 240, 240),
    ]

    /// Create a new terminal session (runs shell directly for full truecolor).
    init(index: Int, fontSize: CGFloat = 13, appearance: NookState.Appearance = .dark,
         initialSize: CGSize = CGSize(width: 426, height: 552)) {
        let name = "sidenook-\(index)"
        self.screenName = name
        self.title = "Terminal \(index)"
        self.coordinator = SessionCoordinator()
        self.terminalView = SideNookTerminalView(
            frame: NSRect(origin: .zero, size: initialSize)
        )

        configureView(fontSize: fontSize, appearance: appearance)
        coordinator.session = self
        terminalView.processDelegate = coordinator
        // Process is started lazily via startProcessIfNeeded(), called from
        // TerminalWrapperView.onFirstLayout so the PTY gets the correct
        // terminal dimensions after SwiftUI layout has settled.
    }

    /// Called once by TerminalWrapperView after its first non-zero layout pass.
    /// Idempotent — safe to call multiple times across tab switches.
    func startProcessIfNeeded() {
        guard !processStarted else { return }
        processStarted = true
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["COLORTERM"] = "truecolor"
        // Hint to color-aware CLIs (Claude Code, bat, delta, etc.) about bg brightness.
        // "15;0" = light fg on dark bg (dark mode). "0;15" = dark fg on light bg (light mode).
        env["COLORFGBG"] = currentAppearance == .dark ? "15;0" : "0;15"
        let envArray = env.map { "\($0.key)=\($0.value)" }
        terminalView.startProcess(executable: shell, args: ["-l"], environment: envArray)

        if let dir = restoreDirectory {
            restoreDirectory = nil
            // Wait for the shell to finish initialising before sending the cd.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self, isAlive else { return }
                let bytes = Array("cd \(dir)\n".utf8)
                terminalView.send(data: bytes[...])
            }
        }
    }

    private func configureView(fontSize: CGFloat, appearance: NookState.Appearance) {
        let font = NSFont(name: "SF Mono", size: fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        terminalView.font = font
        // Show hollow caret when the panel loses focus, matching Terminal.app behavior.
        terminalView.caretViewTracksFocus = true
        applyAppearance(appearance)
    }

    func applyAppearance(_ appearance: NookState.Appearance) {
        currentAppearance = appearance
        switch appearance {
        case .dark:
            terminalView.nativeBackgroundColor = NSColor(red: 0.114, green: 0.118, blue: 0.141, alpha: 1)
            terminalView.nativeForegroundColor = NSColor(red: 0.910, green: 0.910, blue: 0.918, alpha: 1)
            // Dark mode: light sky-blue selection — pale enough to read on a dark background.
            terminalView.selectedTextBackgroundColor = NSColor(red: 0.55, green: 0.80, blue: 1.0, alpha: 0.38)
            terminalView.installColors(Self.darkPalette)
        case .light:
            terminalView.nativeBackgroundColor = NSColor(red: 0.961, green: 0.961, blue: 0.957, alpha: 1)
            terminalView.nativeForegroundColor = NSColor(red: 0.110, green: 0.110, blue: 0.118, alpha: 1)
            // Light mode: pale sky-blue selection — high brightness so it reads as light blue at any alpha.
            terminalView.selectedTextBackgroundColor = NSColor(red: 0.60, green: 0.84, blue: 1.0, alpha: 0.55)
            terminalView.installColors(Self.lightPalette)
        }
        // Signal running CLIs (Claude Code, bat, etc.) to re-query terminal background
        // and redraw with the new colour scheme.
        if processStarted {
            kill(terminalView.process.shellPid, SIGWINCH)
        }
    }

    /// Restart the shell process inside the existing terminal view.
    func restart() {
        isAlive = true
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["COLORTERM"] = "truecolor"
        env["COLORFGBG"] = currentAppearance == .dark ? "15;0" : "0;15"
        let envArray = env.map { "\($0.key)=\($0.value)" }
        terminalView.startProcess(executable: shell, args: ["-l"], environment: envArray)
    }

    func terminate() {
        isAlive = false
        status = .dead
    }

    func send(text: String) {
        guard processStarted else { return }
        markUserInput()
        let bytes = Array(text.utf8)
        terminalView.send(data: bytes[...])
    }

    /// Promote `.idle` → `.live` on first sign of user input. Keeps `.attn`
    /// and `.dead` intact so detectors and lifecycle states aren't clobbered.
    func markUserInput() {
        hasTyped = true
        if status == .idle { status = .live }
    }

    // MARK: - Attention detection

    /// Substrings present only when the terminal is blocking on user input.
    /// Matched case-insensitively against the bottom rows of the visible buffer.
    private static let attnPatterns: [String] = [
        // Claude Code numbered selector — ❯ marks the highlighted option.
        "❯ 1.", "❯ 2.", "❯ 3.", "❯ 4.", "❯ 5.",
        "❯ 6.", "❯ 7.", "❯ 8.", "❯ 9.",
        // Claude Code tool-approval footers.
        "esc to cancel",
        // "shift+tab" appears in the "allow all edits" option on every approval prompt.
        "shift+tab",
        // Generic confirmation prompts.
        "[y/n]", "[y/n]?", "(y/n)", "(yes/no)",
        // Sudo and password prompts.
        "password:", "password for ",
        // Common "press to continue" prompts.
        "press enter to continue", "press any key to continue",
    ]

    /// Substrings that definitively indicate the session is NOT blocked on
    /// input. Any match here wins over attnPatterns and returns false.
    /// "esc to interrupt" appears in Claude Code's status footer while it is
    /// actively running — never during an approval prompt.
    private static let runningIndicators: [String] = [
        "esc to interrupt",
    ]

    /// Rows from the bottom of the visible buffer to scan. Keeping this small
    /// (≤ 12) prevents false positives from grep / cat output that happens to
    /// contain attn-pattern strings (e.g. reading TerminalSession.swift itself
    /// shows "esc to cancel" as a Swift string literal). The active approval
    /// prompt always appears within a few rows of the cursor.
    private static let attnScanRows: Int = 12

    /// Recomputes `status` from the current terminal buffer. Called periodically
    /// by `NookState`'s status poller while sessions are alive.
    /// - Order of precedence: `.dead` (sticky) → `.attn` (prompt detected) →
    ///   `.live` (user has typed) → `.idle`.
    func refreshStatusFromBuffer() {
        guard status != .dead else { return }
        let detected = detectAttentionPrompt()
        let next: NookState.SessionStatus
        if detected            { next = .attn }
        else if hasTyped       { next = .live }
        else                   { next = .idle }
        if status != next { status = next }
    }

    private func detectAttentionPrompt() -> Bool {
        let term = terminalView.getTerminal()
        let total = term.rows
        guard total > 0 else { return false }
        let scan = min(total, Self.attnScanRows)
        let start = total - scan
        var blob = ""
        for r in start..<total {
            guard let line = term.getLine(row: r) else { continue }
            blob += line.translateToString(trimRight: true)
            blob += "\n"
        }
        let lower = blob.lowercased()
        // Running indicators win — if Claude Code is actively executing, it is
        // never simultaneously waiting for approval input.
        if Self.runningIndicators.contains(where: { lower.contains($0) }) {
            return false
        }
        return Self.attnPatterns.contains { lower.contains($0.lowercased()) }
    }
}

/// Minimal subclass of LocalProcessTerminalView with two AppKit overrides:
///
/// • `acceptsFirstMouse` — without this, AppKit skips `mouseDown` delivery when
///   the panel is not key. SwiftTerm's `mouseDown` clears `selection.active`;
///   if it never fires, a stale selection extends on the first drag instead of
///   starting fresh, producing wrong or empty selections.
///
/// • `mouseDownCanMoveWindow` — explicitly false so three-finger trackpad drags
///   always perform text selection, never panel movement.
final class SideNookTerminalView: LocalProcessTerminalView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }
}

// MARK: - Session Coordinator

@MainActor
final class SessionCoordinator: @unchecked Sendable, LocalProcessTerminalViewDelegate {
    weak var session: TerminalSession?

    nonisolated func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    nonisolated func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        Task { @MainActor [weak self] in
            guard let self, let session = self.session else { return }
            if !title.isEmpty {
                session.title = title
            }
        }
    }

    nonisolated func hostCurrentDirectoryUpdate(source: SwiftTerm.TerminalView, directory: String?) {
        Task { @MainActor [weak self] in
            guard let self, let session = self.session, let dir = directory else { return }
            session.currentDirectory = dir
            let name = (dir as NSString).lastPathComponent
            if !name.isEmpty {
                session.title = name
            }
        }
    }

    nonisolated func processTerminated(source: SwiftTerm.TerminalView, exitCode: Int32?) {
        Task { @MainActor [weak self] in
            self?.session?.isAlive = false
            self?.session?.status = .dead
        }
    }
}
