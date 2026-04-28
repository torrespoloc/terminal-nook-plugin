// Sources/SideNook/AppDelegate.swift
import AppKit
import SwiftUI
import SwiftTerm

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    enum Constants {
        static let pillWidth: CGFloat = 9
        static let pillHeight: CGFloat = 128
        static let hitTestDepth: CGFloat = 20
    }

    private let state = NookState()
    private var panel: SideNookPanel!
    private var monitor: Any?
    private var moveObserver: NSObjectProtocol?
    private var keyMonitor: Any?
    private var globalHotkeyMonitor: Any?
    private var statusPollTimer: Timer?
    private var statusItem: NSStatusItem?
    private var keyObservers: [NSObjectProtocol] = []
    /// Guards against circular updates: setFrame → didMove → applyStateChange → setFrame
    private var isUpdatingFrame = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard NSScreen.main != nil else { return }
        setupStatusItem()

        let pillSize = pillDimensions(for: state.dockedEdge)
        panel = SideNookPanel(
            contentRect: NSRect(origin: state.panelPosition, size: pillSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        let rootView = SideNookView(state: state)
        let hostingView = TrackingHostingView(
            rootView: rootView,
            onMouseExit: { [weak self] in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    guard let self else { return }
                    let mouse = NSEvent.mouseLocation
                    if !self.state.isPinned && !self.panel.frame.contains(mouse) {
                        self.collapse()
                    }
                }
            }
        )

        panel.onDragEnd = { [weak self] in
            self?.snapToNearestEdge()
        }
        panel.contentView = hostingView
        panel.ignoresMouseEvents = true
        panel.orderFrontRegardless()

        // Global mouse-move monitor for edge hit-test
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            guard let self else { return }
            let mouse = NSEvent.mouseLocation
            let hitRect = self.hitTestRect()
            if hitRect.contains(mouse) && !self.state.isExpanded {
                self.expand()
            }
        }

        // Track panel moves (drag) — only update position, don't trigger recomputation
        moveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.state.isExpanded, !self.isUpdatingFrame else { return }
                self.state.panelPosition = self.panel.frame.origin
            }
        }

        // Keyboard shortcuts matching Terminal.app
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            let cmd = event.modifierFlags.contains(.command)
            let shift = event.modifierFlags.contains(.shift)
            let chars = event.charactersIgnoringModifiers ?? ""

            // Any keystroke that reaches the terminal (i.e. not consumed as a
            // Cmd-shortcut below) counts as user input — flip the active
            // session from .idle → .live so its dot turns green.
            if !cmd, event.window === self.panel {
                self.state.activeSession?.markUserInput()
                return event
            }
            guard cmd else { return event }

            switch chars {
            case "+", "=":
                self.state.zoomIn(); return nil
            case "-":
                self.state.zoomOut(); return nil
            case "0":
                self.state.fontSize = 13
                self.state.applyFontToAllSessions()
                return nil
            case "t" where !shift:
                if self.state.sessions.count < NookState.maxTabs {
                    self.state.createSession()
                }
                return nil
            case "w" where !shift:
                if let id = self.state.activeSessionID {
                    self.state.closeSession(id)
                }
                return nil
            case "[" where shift, "{":
                self.switchToPreviousTab(); return nil
            case "]" where shift, "}":
                self.switchToNextTab(); return nil
            case "k":
                if let session = self.state.activeSession {
                    session.terminalView.feed(text: "\u{1b}[2J\u{1b}[3J\u{1b}[H")
                }
                return nil
            case "l":
                if let session = self.state.activeSession {
                    session.terminalView.feed(text: "\u{1b}[2J\u{1b}[3J\u{1b}[H")
                }
                return nil
            case "v":
                if let session = self.state.activeSession {
                    session.terminalView.paste(session.terminalView)
                }
                return nil
            case "c":
                if let session = self.state.activeSession {
                    session.terminalView.copy(session.terminalView)
                }
                return nil
            case "z":
                if let session = self.state.activeSession {
                    session.send(text: "\u{1f}")
                }
                return nil
            case ",":
                if self.state.canTogglePopover() { self.state.showSettings.toggle() }
                return nil
            case "q":
                NSApp.terminate(nil)
                return nil
            case "f" where !shift:
                if self.state.activeSession != nil {
                    self.state.findVisible.toggle()
                    if !self.state.findVisible { self.state.findQuery = "" }
                }
                return nil
            case "g" where !shift:
                if let session = self.state.activeSession,
                   !self.state.findQuery.isEmpty {
                    session.terminalView.findNext(
                        self.state.findQuery,
                        options: SwiftTerm.SearchOptions(caseSensitive: false, regex: false, wholeWord: false),
                        scrollToResult: true
                    )
                }
                return nil
            case "G":
                if let session = self.state.activeSession,
                   !self.state.findQuery.isEmpty {
                    session.terminalView.findPrevious(
                        self.state.findQuery,
                        options: SwiftTerm.SearchOptions(caseSensitive: false, regex: false, wholeWord: false),
                        scrollToResult: true
                    )
                }
                return nil
            case "1", "2", "3", "4", "5", "6", "7", "8", "9":
                if let num = Int(chars) {
                    let index = num - 1
                    if index < self.state.sessions.count {
                        self.state.switchToSession(self.state.sessions[index].id)
                    }
                }
                return nil
            default:
                break
            }

            // Scrollback navigation — these use keyCode, not character, because arrow/page keys
            // don't produce printable chars. Only intercept Cmd+<key>; pass everything else through.
            switch event.keyCode {
            case 126: // Cmd + ↑ — scroll up one line
                self.state.activeSession?.terminalView.scrollUp(lines: 1)
                return nil
            case 125: // Cmd + ↓ — scroll down one line
                self.state.activeSession?.terminalView.scrollDown(lines: 1)
                return nil
            case 116: // Cmd + Page Up — scroll one full page up
                if let session = self.state.activeSession {
                    let rows = session.terminalView.getTerminal().rows
                    session.terminalView.scrollUp(lines: rows)
                }
                return nil
            case 121: // Cmd + Page Down — scroll one full page down
                if let session = self.state.activeSession {
                    let rows = session.terminalView.getTerminal().rows
                    session.terminalView.scrollDown(lines: rows)
                }
                return nil
            case 115: // Cmd + Home — scroll to top of buffer (clamped by SwiftTerm)
                self.state.activeSession?.terminalView.scrollUp(lines: 50_000)
                return nil
            case 119: // Cmd + End — scroll to bottom of buffer (clamped by SwiftTerm)
                self.state.activeSession?.terminalView.scrollDown(lines: 50_000)
                return nil
            default:
                return event
            }
        }

        // Global hotkey: ⌃` (Control + backtick, keyCode 50) toggles expand/collapse
        // from any app. The event is observed but not consumed (requires CGEventTap
        // for consumption — acceptable for this shortcut which rarely conflicts).
        globalHotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return }
            if event.keyCode == 50 && event.modifierFlags.intersection([.control, .command, .shift, .option]) == .control {
                DispatchQueue.main.async {
                    if self.state.isExpanded { self.collapse() } else { self.expand() }
                }
            }
        }

        startObservingState()
        startObservingWindowFocus()
        startStatusPolling()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.checkFullDiskAccess()
        }
    }

    private func checkFullDiskAccess() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "fdaPrompted") else { return }
        defaults.set(true, forKey: "fdaPrompted")

        let hasAccess = FileManager.default.isReadableFile(
            atPath: "/Library/Application Support/com.apple.TCC/TCC.db"
        )
        guard !hasAccess else { return }

        let alert = NSAlert()
        alert.messageText = "Allow SideNook Full Disk Access"
        alert.informativeText = """
            SideNook runs a terminal shell. Without Full Disk Access, macOS will ask for permission \
            every session — for Documents, Music, Photos, and more — even when those belong to tools \
            running inside the terminal (like Claude Code).

            Grant Full Disk Access once and the prompts stop permanently.
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Not Now")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
            )
        }
    }

    /// Polls each session's terminal buffer to drive the `.attn` (yellow dot)
    /// state. Runs on the main runloop in `.common` mode so it keeps firing
    /// during scrolls and drags. Cheap — reads at most ~24 visible rows per
    /// session and only writes `status` when it actually changes.
    private func startStatusPolling() {
        let timer = Timer(timeInterval: 0.4, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                for session in self.state.sessions {
                    session.refreshStatusFromBuffer()
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        statusPollTimer = timer
    }

    // MARK: - Status Bar Item

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            if let url = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png"),
               let img = NSImage(contentsOf: url) {
                img.isTemplate = true
                button.image = img
            }
            button.imagePosition = .imageOnly
            button.toolTip = "SideNook"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show/Hide SideNook", action: #selector(togglePanel), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Pin/Unpin SideNook", action: #selector(togglePinFromMenu), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit SideNook", action: #selector(quitApp), keyEquivalent: "q"))
        item.menu = menu

        statusItem = item
    }

    @objc private func togglePanel() {
        if state.isExpanded {
            collapse()
        } else {
            expand()
        }
    }

    @objc private func togglePinFromMenu() {
        state.togglePin()
        if state.isPinned && !state.isExpanded {
            expand()
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Window Focus → Cursor Blink

    private func startObservingWindowFocus() {
        let becomeKey = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, let session = self.state.activeSession else { return }
                self.state.isWindowActive = true
                self.panel.makeFirstResponder(session.terminalView)
            }
        }

        let resignKey = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.state.isWindowActive = false
                // Yield first responder so SwiftTerm calls resignFirstResponder
                // → caretViewTracksFocus draws hollow cursor, stops blink.
                self.panel.makeFirstResponder(self.panel.contentView)
            }
        }

        keyObservers = [becomeKey, resignKey]
    }

    // MARK: - State Observation

    private func startObservingState() {
        withObservationTracking {
            _ = state.isExpanded
            _ = state.isPinned
            _ = state.dockedEdge
            // Note: NOT observing expandedSize or panelPosition here —
            // those are updated directly by resize handles and drag,
            // which manage the panel frame themselves.
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.applyStateChange()
                self?.startObservingState()
            }
        }
    }

    // MARK: - Expand / Collapse

    private func expand() {
        guard !state.isExpanded else { return }
        // Resize the panel BEFORE flipping isExpanded so SwiftUI's first render of
        // ExpandedView lands in a correctly-sized frame — no intermediate squished state.
        let screenFrame = panelScreen.visibleFrame
        let size = NSSize(width: state.expandedSize.width, height: state.expandedSize.height)
        let pos = clampToScreen(
            origin: expandedOrigin(screenFrame: screenFrame),
            size: size,
            screenFrame: screenFrame
        )
        isUpdatingFrame = true
        state.panelPosition = pos
        panel.setFrame(NSRect(origin: pos, size: size), display: true, animate: false)
        panel.ignoresMouseEvents = false
        isUpdatingFrame = false
        // State flip happens after frame — SwiftUI renders ExpandedView into the correct size.
        state.expand()
        panel.makeKey()
    }

    private func collapse() {
        guard state.isExpanded else { return }
        panel.resignKey()
        // State flip first — SwiftUI immediately shows PillView.
        // Frame shrinks after, so PillView renders at the correct pill size from the start.
        state.collapse()
        let screenFrame = panelScreen.visibleFrame
        let pillSize = pillDimensions(for: state.dockedEdge)
        let pos = pillOrigin(screenFrame: screenFrame)
        isUpdatingFrame = true
        state.panelPosition = pos
        panel.setFrame(NSRect(origin: pos, size: pillSize), display: true, animate: false)
        panel.ignoresMouseEvents = true
        isUpdatingFrame = false
    }

    // MARK: - Apply State Changes

    private func applyStateChange() {
        let screenFrame = panelScreen.visibleFrame

        // If unpinned while expanded, check if mouse is outside and collapse
        if state.isExpanded && !state.isPinned {
            let mouse = NSEvent.mouseLocation
            if !panel.frame.contains(mouse) {
                collapse()
                return
            }
        }

        isUpdatingFrame = true
        defer { isUpdatingFrame = false }

        if state.isExpanded {
            let size = NSSize(
                width: state.expandedSize.width,
                height: state.expandedSize.height
            )
            // Only reposition when the frame size differs (e.g. first expand or size change).
            // Skipping reposition when already expanded keeps the window where the user placed it
            // — prevents pin/unpin from snapping back to the pill-anchor-derived position.
            if panel.frame.size != size {
                let pos = clampToScreen(
                    origin: expandedOrigin(screenFrame: screenFrame),
                    size: size,
                    screenFrame: screenFrame
                )
                state.panelPosition = pos
                panel.setFrame(NSRect(origin: pos, size: size), display: true, animate: false)
            }
            panel.ignoresMouseEvents = false
            panel.makeKey()
        } else {
            panel.resignKey()
            let pillSize = pillDimensions(for: state.dockedEdge)
            let pos = pillOrigin(screenFrame: screenFrame)
            state.panelPosition = pos
            panel.setFrame(NSRect(origin: pos, size: pillSize), display: true, animate: false)
            panel.ignoresMouseEvents = true
        }
    }

    // MARK: - Edge-Adaptive Geometry

    private func pillDimensions(for edge: NookState.ScreenEdge) -> NSSize {
        switch edge {
        case .left, .right:
            return NSSize(width: Constants.pillWidth, height: Constants.pillHeight)
        case .top, .bottom:
            return NSSize(width: Constants.pillHeight, height: Constants.pillWidth)
        }
    }

    /// Pill origin when collapsing — derived from the stable pillEdgeOffset anchor,
    /// not from the expanded panel position, so the pill never drifts.
    private func pillOrigin(screenFrame: NSRect) -> CGPoint {
        let offset = state.pillEdgeOffset
        switch state.dockedEdge {
        case .left:
            return CGPoint(x: screenFrame.minX, y: offset)
        case .right:
            return CGPoint(x: screenFrame.maxX - Constants.pillWidth, y: offset)
        case .top:
            return CGPoint(x: offset, y: screenFrame.maxY - Constants.pillWidth)
        case .bottom:
            return CGPoint(x: offset, y: screenFrame.minY)
        }
    }

    /// Expanded origin — derived from the stable pillEdgeOffset anchor.
    /// Top/bottom: aligns left or right edge of window with pill based on 50% breakpoint.
    /// Left/right: centers vertically on pill midpoint.
    private func expandedOrigin(screenFrame: NSRect) -> CGPoint {
        let offset = state.pillEdgeOffset
        let w = state.expandedSize.width
        let h = state.expandedSize.height
        switch state.dockedEdge {
        case .left:
            return CGPoint(x: screenFrame.minX,
                           y: offset + Constants.pillHeight / 2 - h / 2)
        case .right:
            return CGPoint(x: screenFrame.maxX - w,
                           y: offset + Constants.pillHeight / 2 - h / 2)
        case .top:
            let pillCenterX = offset + Constants.pillHeight / 2
            if pillCenterX < screenFrame.midX {
                return CGPoint(x: offset, y: screenFrame.maxY - h)
            } else {
                return CGPoint(x: offset + Constants.pillHeight - w, y: screenFrame.maxY - h)
            }
        case .bottom:
            let pillCenterX = offset + Constants.pillHeight / 2
            if pillCenterX < screenFrame.midX {
                return CGPoint(x: offset, y: screenFrame.minY)
            } else {
                return CGPoint(x: offset + Constants.pillHeight - w, y: screenFrame.minY)
            }
        }
    }

    /// Hit-test rect for the collapsed pill.
    private func hitTestRect() -> NSRect {
        let panelFrame = panel.frame
        let depth = Constants.hitTestDepth
        switch state.dockedEdge {
        case .left:
            return NSRect(x: panelFrame.minX, y: panelFrame.minY,
                          width: depth, height: panelFrame.height)
        case .right:
            return NSRect(x: panelFrame.maxX - depth, y: panelFrame.minY,
                          width: depth, height: panelFrame.height)
        case .top:
            return NSRect(x: panelFrame.minX, y: panelFrame.maxY - depth,
                          width: panelFrame.width, height: depth)
        case .bottom:
            return NSRect(x: panelFrame.minX, y: panelFrame.minY,
                          width: panelFrame.width, height: depth)
        }
    }

    // MARK: - Snap to Edge

    func snapToNearestEdge() {
        let screenFrame = panelScreen.visibleFrame
        let panelFrame = panel.frame
        let center = CGPoint(x: panelFrame.midX, y: panelFrame.midY)
        let edge = nearestScreenEdge(panelCenter: center, screenFrame: screenFrame)
        let nextOffset: CGFloat = {
            switch edge {
            case .left, .right: return panelFrame.midY - Constants.pillHeight / 2
            case .top, .bottom: return panelFrame.midX - Constants.pillHeight / 2
            }
        }()
        // Animate the edge / offset transition so layout flips (e.g. sidebar moving left↔right) glide smoothly.
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            state.dockedEdge = edge
            state.pillEdgeOffset = nextOffset
        }
    }

    // MARK: - Tab Navigation

    private func switchToNextTab() {
        guard let activeID = state.activeSessionID,
              let index = state.sessions.firstIndex(where: { $0.id == activeID }) else { return }
        let next = (index + 1) % state.sessions.count
        state.switchToSession(state.sessions[next].id)
    }

    private func switchToPreviousTab() {
        guard let activeID = state.activeSessionID,
              let index = state.sessions.firstIndex(where: { $0.id == activeID }) else { return }
        let prev = (index - 1 + state.sessions.count) % state.sessions.count
        state.switchToSession(state.sessions[prev].id)
    }

    // MARK: - Helpers

    /// The screen that currently contains the panel, used for all geometry.
    /// Falls back gracefully so callers never receive nil.
    private var panelScreen: NSScreen {
        NSScreen.screens.first { $0.frame.intersects(panel.frame) }
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }

    private func clampToScreen(origin: CGPoint, size: NSSize, screenFrame: NSRect) -> CGPoint {
        let x = min(max(origin.x, screenFrame.minX), screenFrame.maxX - size.width)
        let y = min(max(origin.y, screenFrame.minY), screenFrame.maxY - size.height)
        return CGPoint(x: x, y: y)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor { NSEvent.removeMonitor(monitor) }
        if let moveObserver { NotificationCenter.default.removeObserver(moveObserver) }
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        if let globalHotkeyMonitor { NSEvent.removeMonitor(globalHotkeyMonitor) }
        for obs in keyObservers { NotificationCenter.default.removeObserver(obs) }
        statusPollTimer?.invalidate()
        state.saveSessionSnapshots()
        for session in state.sessions { session.terminate() }
    }
}
