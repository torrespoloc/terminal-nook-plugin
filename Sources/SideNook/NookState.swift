// Sources/SideNook/NookState.swift
import Observation
import AppKit
import ServiceManagement

@MainActor
@Observable
final class NookState {
    static let minExpandedSize = CGSize(width: 300, height: 300)
    static let maxExpandedSize = CGSize(width: 900, height: 900)
    static let maxTabs = 20
    static let minFontSize: CGFloat = 9
    static let maxFontSize: CGFloat = 28
    static let fontSizeStep: CGFloat = 2

    enum ScreenEdge: String, CaseIterable {
        case left, right, top, bottom
    }

    enum Appearance: String {
        case dark, light
    }

    enum TabLayout: String {
        case topBar, leftSidebar
    }

    var isExpanded: Bool = false
    var isPinned: Bool = false
    var panelPosition: CGPoint
    var pillEdgeOffset: CGFloat = 0  // X for top/bottom edges; Y for left/right edges
    var expandedSize: CGSize = CGSize(width: 450, height: 600)
    var dockedEdge: ScreenEdge = .top
    var appearance: Appearance = .dark
    var tabLayout: TabLayout = .leftSidebar {
        didSet {
            guard oldValue != tabLayout, isExpanded else { return }
            let h = expandedSize.height
            expandedSize = tabLayout == .topBar
                ? CGSize(width: 720, height: h)
                : CGSize(width: 820, height: h)
        }
    }
    var fontSize: CGFloat = 13

    var showSettings: Bool = false
    var showAbout: Bool = false
    var reduceMotion: Bool = false
    var showCommandHelp: Bool = false

    // Tab/session management
    var sessions: [TerminalSession] = []
    var activeSessionID: UUID?
    private var sessionCounter: Int = 0

    enum SessionStatus {
        case live   // shell running normally
        case attn   // waiting for user input (sudo, confirmation)
        case dead   // process exited
    }

    var isVerticalEdge: Bool { dockedEdge == .left || dockedEdge == .right }
    var isDark: Bool { appearance == .dark }
    var theme: NookTheme { NookTheme(isDark: isDark) }

    /// Launch at Login via SMAppService. Requires app to be installed (not run from swift build).
    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue { try SMAppService.mainApp.register() }
                else        { try SMAppService.mainApp.unregister() }
            } catch { /* silently fail if app isn't properly installed */ }
        }
    }

    var activeSession: TerminalSession? {
        sessions.first { $0.id == activeSessionID }
    }

    private var contentSize: CGSize {
        CGSize(
            width: expandedSize.width - 24,
            height: expandedSize.height - 48
        )
    }

    init() {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let frame = screen.visibleFrame
        // Default: top edge, pill centered horizontally
        let centerOffset = frame.midX - 60  // 60 = pillHeight/2
        self.panelPosition = CGPoint(x: centerOffset, y: frame.maxY - 6)
        self.pillEdgeOffset = centerOffset
        // Create one default session
        let _ = createSession()
    }

    func expand()   { isExpanded = true }
    func collapse() { isPinned = false; isExpanded = false }
    func toggle()   { isExpanded.toggle() }
    func togglePin() { isPinned.toggle() }

    func toggleAppearance() {
        appearance = isDark ? .light : .dark
        applyAppearanceToAllSessions()
    }

    func zoomIn() {
        fontSize = min(fontSize + Self.fontSizeStep, Self.maxFontSize)
        applyFontToAllSessions()
    }

    func zoomOut() {
        fontSize = max(fontSize - Self.fontSizeStep, Self.minFontSize)
        applyFontToAllSessions()
    }

    func applyFontToAllSessions() {
        let font = NSFont(name: "SF Mono", size: fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        for session in sessions {
            session.terminalView.font = font
        }
    }

    private func applyAppearanceToAllSessions() {
        for session in sessions {
            session.applyAppearance(appearance)
        }
    }

    // MARK: - Session Management

    @discardableResult
    func createSession() -> TerminalSession {
        sessionCounter += 1
        let session = TerminalSession(
            index: sessionCounter,
            fontSize: fontSize,
            appearance: appearance,
            initialSize: contentSize
        )
        sessions.append(session)
        activeSessionID = session.id
        return session
    }

    func closeSession(_ id: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }

        if sessions.count == 1 {
            createSession()
        }

        let session = sessions[index]
        session.terminate()
        sessions.remove(at: index)

        if activeSessionID == id {
            let newIndex = min(index, sessions.count - 1)
            activeSessionID = sessions[newIndex].id
        }
    }

    func switchToSession(_ id: UUID) {
        activeSessionID = id
    }

    func reorderSessions(fromID: UUID, toID: UUID) {
        guard fromID != toID,
              let fromIdx = sessions.firstIndex(where: { $0.id == fromID }),
              let toIdx   = sessions.firstIndex(where: { $0.id == toID })
        else { return }
        sessions.move(fromOffsets: IndexSet(integer: fromIdx),
                      toOffset: toIdx > fromIdx ? toIdx + 1 : toIdx)
    }
}
