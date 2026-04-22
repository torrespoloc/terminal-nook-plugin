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

    let terminalView: LocalProcessTerminalView
    private let coordinator: SessionCoordinator

    init(index: Int) {
        self.title = "Terminal \(index)"
        self.coordinator = SessionCoordinator()
        self.terminalView = LocalProcessTerminalView(frame: .zero)

        // Configure appearance
        let font = NSFont(name: "SF Mono", size: 13)
            ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        terminalView.font = font
        terminalView.nativeBackgroundColor = NSColor.black
        terminalView.nativeForegroundColor = NSColor(white: 0.85, alpha: 1)

        // Wire delegate
        coordinator.session = self
        terminalView.processDelegate = coordinator

        // Start login shell
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        terminalView.startProcess(executable: shell, args: ["-l"])
    }

    func terminate() {
        // The terminal view will clean up its process on dealloc
        isAlive = false
    }
}

// MARK: - Session Coordinator

/// Receives SwiftTerm delegate callbacks and updates the owning TerminalSession.
/// Made @MainActor + @unchecked Sendable so the weak session reference is safe.
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
        }
    }
}
