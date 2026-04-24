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
    var status: NookState.SessionStatus = .live
    let screenName: String
    let isExternal: Bool = false

    let terminalView: LocalProcessTerminalView
    private let coordinator: SessionCoordinator

    /// Absolute buffer row indices (yDisp + buffer.y) where the user submitted input.
    var inputHighlightRows: [Int] = []

    // MARK: - ANSI Color Palettes (matching Terminal.app)

    private static func c(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> SwiftTerm.Color {
        SwiftTerm.Color(red: r * 257, green: g * 257, blue: b * 257)
    }

    /// Dark mode palette — matches macOS Terminal.app "Basic" profile
    private static let darkPalette: [SwiftTerm.Color] = [
        c(0,   0,   0),     c(194, 54,  33),    c(37,  188, 36),    c(173, 173, 39),
        c(73,  46,  225),   c(211, 56,  211),   c(51,  187, 200),   c(203, 204, 205),
        c(129, 131, 131),   c(252, 57,  31),    c(49,  231, 34),    c(234, 236, 35),
        c(88,  51,  255),   c(249, 53,  248),   c(20,  240, 240),   c(233, 235, 235),
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
        self.terminalView = LocalProcessTerminalView(
            frame: NSRect(origin: .zero, size: initialSize)
        )

        configureView(fontSize: fontSize, appearance: appearance)
        coordinator.session = self
        terminalView.processDelegate = coordinator

        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["COLORTERM"] = "truecolor"
        let envArray = env.map { "\($0.key)=\($0.value)" }
        terminalView.startProcess(
            executable: shell,
            args: ["-l"],
            environment: envArray
        )
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
        switch appearance {
        case .dark:
            terminalView.nativeBackgroundColor = NSColor.black
            terminalView.nativeForegroundColor = NSColor(white: 0.85, alpha: 1)
            terminalView.installColors(Self.darkPalette)
        case .light:
            terminalView.nativeBackgroundColor = NSColor(white: 0.97, alpha: 1)
            terminalView.nativeForegroundColor = NSColor(white: 0.12, alpha: 1)
            terminalView.installColors(Self.lightPalette)
        }
    }

    /// Records the current cursor row as a user-input row for highlight rendering.
    /// Stores absolute buffer position so the highlight stays correct as content scrolls.
    func recordInputRow() {
        let term = terminalView.getTerminal()
        let absRow = term.buffer.yDisp + term.buffer.y
        if inputHighlightRows.last != absRow {
            inputHighlightRows.append(absRow)
            if inputHighlightRows.count > 200 {
                inputHighlightRows.removeFirst()
            }
        }
    }

    /// Restart the shell process inside the existing terminal view.
    /// Clears highlight rows but preserves scroll buffer so history stays visible.
    func restart() {
        isAlive = true
        inputHighlightRows = []
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        var env = ProcessInfo.processInfo.environment
        env["TERM"] = "xterm-256color"
        env["COLORTERM"] = "truecolor"
        let envArray = env.map { "\($0.key)=\($0.value)" }
        terminalView.startProcess(executable: shell, args: ["-l"], environment: envArray)
    }

    func terminate() {
        isAlive = false
        status = .dead
    }
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
