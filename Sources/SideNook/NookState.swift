// Sources/SideNook/NookState.swift
import Observation
import AppKit

@MainActor
@Observable
final class NookState {
    static let minExpandedSize = CGSize(width: 300, height: 300)
    static let maxExpandedSize = CGSize(width: 900, height: 900)
    static let maxTabs = 20

    enum ScreenEdge: String, CaseIterable {
        case left, right, top, bottom
    }

    var isExpanded: Bool = false
    var isPinned: Bool = false
    var panelPosition: CGPoint
    var expandedSize: CGSize = CGSize(width: 450, height: 600)
    var dockedEdge: ScreenEdge = .left

    // Tab/session management
    var sessions: [TerminalSession] = []
    var activeSessionID: UUID?
    private var sessionCounter: Int = 0

    var isVerticalEdge: Bool { dockedEdge == .left || dockedEdge == .right }

    var activeSession: TerminalSession? {
        sessions.first { $0.id == activeSessionID }
    }

    init() {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let frame = screen.visibleFrame
        self.panelPosition = CGPoint(
            x: frame.minX,
            y: frame.midY - 60
        )
        // Create the first session
        let _ = createSession()
    }

    func expand()   { isExpanded = true }
    func collapse() { isPinned = false; isExpanded = false }
    func toggle()   { isExpanded.toggle() }
    func togglePin() { isPinned.toggle() }

    @discardableResult
    func createSession() -> TerminalSession {
        sessionCounter += 1
        let session = TerminalSession(index: sessionCounter)
        sessions.append(session)
        activeSessionID = session.id
        return session
    }

    func closeSession(_ id: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }

        // If closing the last tab, create a new one first
        if sessions.count == 1 {
            createSession()
        }

        let session = sessions[index]
        session.terminate()
        sessions.remove(at: index)

        // Switch to adjacent tab if we closed the active one
        if activeSessionID == id {
            let newIndex = min(index, sessions.count - 1)
            activeSessionID = sessions[newIndex].id
        }
    }

    func switchToSession(_ id: UUID) {
        activeSessionID = id
    }
}
