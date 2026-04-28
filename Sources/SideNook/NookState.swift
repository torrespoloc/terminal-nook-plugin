// Sources/SideNook/NookState.swift
import Observation
import AppKit
import ServiceManagement
import SwiftUI

@MainActor
@Observable
final class NookState {
    static let minExpandedSize = CGSize(width: 300, height: 300)
    static let maxExpandedSize = CGSize(width: 800, height: 1100)
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
    var accentHex: String = "#35d07f"
    var accentColor: Color { Color(hex: accentHex) ?? theme.defaultAccent }
    var fontSize: CGFloat = 13

    var isWindowActive: Bool = true
    var isMaximized: Bool = false

    var showSettings: Bool = false
    var showAbout: Bool = false
    var reduceMotion: Bool = false
    var showCommandHelp: Bool = false

    // Find bar (⌘F) — visible state and query string. Active session only.
    var findVisible: Bool = false
    var findQuery: String = ""

    /// Timestamp of the most recent popover auto-dismiss. Used to debounce the
    /// trigger button: AppKit treats a click on the anchor button as "outside"
    /// the popover, dismissing it, and SwiftUI then delivers the same click to
    /// the Button — without this guard the action toggles the popover back on,
    /// requiring a double-click to actually close it.
    @ObservationIgnored
    private var lastPopoverDismiss: Date = .distantPast

    func canTogglePopover() -> Bool {
        Date().timeIntervalSince(lastPopoverDismiss) >= 0.25
    }

    func notePopoverDismissed() {
        lastPopoverDismiss = Date()
    }

    // Tab/session management
    var sessions: [TerminalSession] = []
    var activeSessionID: UUID?
    private var sessionCounter: Int = 0

    // MARK: - Session Snapshot Persistence

    private struct SessionSnapshot: Codable {
        var title: String
        var directory: String?
    }

    private static let snapshotsKey = "SideNook.sessionSnapshots"

    /// Saves current session titles and directories to UserDefaults.
    func saveSessionSnapshots() {
        let snapshots = sessions.map { SessionSnapshot(title: $0.title, directory: $0.currentDirectory) }
        if let data = try? JSONEncoder().encode(snapshots) {
            UserDefaults.standard.set(data, forKey: Self.snapshotsKey)
        }
    }

    /// Replaces the default empty session with restored sessions from the last run.
    /// Called from `init` — must run before the default `createSession()`.
    private func restoreSessionSnapshots() {
        guard let data = UserDefaults.standard.data(forKey: Self.snapshotsKey),
              let snapshots = try? JSONDecoder().decode([SessionSnapshot].self, from: data),
              !snapshots.isEmpty
        else { return }

        for snapshot in snapshots {
            sessionCounter += 1
            let session = TerminalSession(
                index: sessionCounter,
                fontSize: fontSize,
                appearance: appearance,
                initialSize: terminalContentSize(for: tabLayout)
            )
            session.title = snapshot.title
            session.restoreDirectory = snapshot.directory
            sessions.append(session)
        }
        activeSessionID = sessions.first?.id
    }

    enum SessionStatus {
        case idle   // shell running but user has not typed yet
        case live   // user has typed at least one character
        case attn   // agent is waiting for user input (e.g. Claude Code prompt)
        case dead   // process exited
    }

    var isVerticalEdge: Bool { dockedEdge == .left || dockedEdge == .right }
    var isDark: Bool { appearance == .dark }
    var theme: NookTheme { NookTheme(isDark: isDark, accent: accentColor) }

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

    private func terminalContentSize(for layout: TabLayout) -> CGSize {
        switch layout {
        case .leftSidebar:
            // HStack padding: leading 8, trailing 8 | SidebarNavView: width 180, HStack spacing 6
            let w = expandedSize.width - 8 - 180 - 6 - 8   // width - 202
            let h = expandedSize.height - 16 - 8             // height - 24 (top 16 + bottom 8)
            return CGSize(width: max(w, 100), height: max(h, 100))
        case .topBar:
            // NavBarView total vertical: 40 frame + 8 top pad + 6 bottom pad = 54
            // Terminal: .padding(.horizontal, 8) + .padding(.top, 16) + .padding(.bottom, 8)
            let w = expandedSize.width - 8 - 8         // width - 16
            let h = expandedSize.height - 54 - 16 - 8  // height - 78 (NavBar 54 + top 16 + bottom 8)
            return CGSize(width: max(w, 100), height: max(h, 100))
        }
    }

    init() {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let frame = screen.visibleFrame
        // Default: left edge, pill near the top of the screen.
        // pillEdgeOffset on a vertical edge is the pill's Y origin (macOS Y is bottom-up,
        // so high Y = near the top). Inset 8pt from the very top for breathing room.
        self.dockedEdge = .left
        let topInset: CGFloat = 8
        let topOffset = frame.maxY - 128 - topInset  // 128 = pillHeight
        self.panelPosition = CGPoint(x: frame.minX, y: topOffset)
        self.pillEdgeOffset = topOffset
        // Restore previous sessions, or create a fresh one if none saved.
        restoreSessionSnapshots()
        if sessions.isEmpty { createSession() }
    }

    func expand() {
        if activeSession == nil, let first = sessions.first {
            activeSessionID = first.id
        }
        isExpanded = true
    }
    func collapse() { isPinned = false; isExpanded = false }
    func toggle()   { isExpanded.toggle() }
    func togglePin() { isPinned.toggle() }
    func quitApp() { NSApplication.shared.terminate(nil) }
    func toggleMaxMin() {
        isMaximized.toggle()
        if isMaximized {
            // True full-screen fill: take the visible frame of the panel's screen.
            // visibleFrame already excludes menu bar + Dock.
            let screen = NSScreen.main ?? NSScreen.screens.first
            let size = screen?.visibleFrame.size ?? NookState.maxExpandedSize
            expandedSize = CGSize(
                width:  min(size.width,  NookState.maxExpandedSize.width),
                height: min(size.height, NookState.maxExpandedSize.height)
            )
        } else {
            expandedSize = NookState.minExpandedSize
        }
    }

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
            initialSize: terminalContentSize(for: tabLayout)
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
