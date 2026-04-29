// Sources/SideNook/Views/NavBarView.swift
import SwiftUI

struct NavBarView: View {
    @Bindable var state: NookState

    private var t: NookTheme { state.theme }

    var body: some View {
        VStack(spacing: 0) {
            primaryRow
            Rectangle().fill(t.stroke1).frame(height: 0.5)
            secondaryRow
        }
        .background(
            RoundedRectangle(cornerRadius: NookRadius.lg, style: .continuous)
                .fill(t.L2)
                .overlay(
                    RoundedRectangle(cornerRadius: NookRadius.lg, style: .continuous)
                        .strokeBorder(t.stroke2, lineWidth: 0.5)
                )
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: NookRadius.lg, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [t.innerHighlight, .clear],
                                startPoint: .top,
                                endPoint: .center
                            ),
                            lineWidth: 0.5
                        )
                        .allowsHitTesting(false)
                }
                .shadow(color: .black.opacity(0.50), radius: 2, y: 1)
        )
        .background(DragHandleView())
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 6, trailing: 8))
    }

    // MARK: - Primary row (traffic lights, layout toggle, tabs, +)

    private var primaryRow: some View {
        HStack(spacing: 0) {
            TrafficLightButtonsView(state: state)
                .padding(.leading, 8)
                .padding(.trailing, 8)

            verticalDivider

            NavIconButton(
                icon: "sidebar.left",
                isOn: false,
                fgMuted: t.fgMute,
                fgActive: t.fg,
                isDark: state.isDark
            ) {
                state.tabLayout = .leftSidebar
            }
            .help("Switch to Sidebar Layout")
            .padding(.horizontal, 4)

            verticalDivider

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    if state.notesTabActive {
                        NotesTabButton(
                            isDark: state.isDark,
                            onClose: { state.closeNotesTab() }
                        )
                    }
                    if state.helpTabActive {
                        HelpTabButton(
                            isDark: state.isDark,
                            onClose: { state.closeHelpTab() }
                        )
                    }
                    ForEach(state.sessions) { session in
                        TabButtonView(
                            session: session,
                            isActive: session.id == state.activeSessionID && !state.notesTabActive && !state.helpTabActive,
                            isDark: state.isDark,
                            onSelect: { state.switchToSession(session.id) },
                            onClose: { state.closeSession(session.id) },
                            onRename: { session.title = $0 }
                        )
                        .onDrop(of: [.text], isTargeted: nil) { providers in
                            providers.first?.loadObject(ofClass: NSString.self) { item, _ in
                                guard let fromIDStr = item as? String,
                                      let fromID = UUID(uuidString: fromIDStr) else { return }
                                Task { @MainActor in
                                    state.reorderSessions(fromID: fromID, toID: session.id)
                                }
                            }
                            return true
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxWidth: .infinity)

            NavIconButton(
                icon: "plus",
                isOn: false,
                fgMuted: t.fgMute,
                fgActive: t.fg,
                isDark: state.isDark,
                tone: .cta
            ) {
                if state.sessions.count < NookState.maxTabs {
                    state.createSession()
                }
            }
            .help("New Tab")
            .padding(.horizontal, 8)
        }
        .frame(height: 40)
    }

    // MARK: - Secondary row (Notes, Help · theme, pin, settings)

    private var secondaryRow: some View {
        HStack(spacing: 4) {
            NavTriggerButton(
                icon: "note.text",
                label: "Notes",
                isOn: state.showNotes,
                isDark: state.isDark,
                trailing: { AnyView(noteCounter) }
            ) {
                if state.canTogglePopover("notes") { state.showNotes.toggle() }
            }
            .popover(
                isPresented: Binding(
                    get: { state.showNotes },
                    set: { newValue in
                        if !newValue && state.showNotes { state.notePopoverDismissed("notes") }
                        state.showNotes = newValue
                    }
                ),
                attachmentAnchor: .point(.bottom),
                arrowEdge: .top
            ) {
                NotesView(state: state, showsTrigger: false)
            }

            NavTriggerButton(
                icon: "info.circle",
                label: "Command Line Help",
                isOn: state.showCommandHelp,
                isDark: state.isDark
            ) {
                if state.canTogglePopover("help") { state.showCommandHelp.toggle() }
            }
            .popover(
                isPresented: Binding(
                    get: { state.showCommandHelp },
                    set: { newValue in
                        if !newValue && state.showCommandHelp { state.notePopoverDismissed("help") }
                        state.showCommandHelp = newValue
                    }
                ),
                attachmentAnchor: .point(.bottom),
                arrowEdge: .top
            ) {
                CommandLineHelpView(state: state, showsTrigger: false)
            }

            Spacer(minLength: 0)

            NavIconButton(
                icon: state.isDark ? "sun.max.fill" : "moon.fill",
                isOn: false,
                fgMuted: t.fgMute,
                fgActive: t.fg,
                isDark: state.isDark
            ) {
                state.toggleAppearance()
            }
            .help(state.isDark ? "Switch to Light Mode" : "Switch to Dark Mode")

            NavIconButton(
                icon: state.isPinned ? "pin.fill" : "pin.slash",
                isOn: state.isPinned,
                fgMuted: t.fgMute,
                fgActive: t.fg,
                isDark: state.isDark
            ) {
                state.togglePin()
            }
            .help(state.isPinned ? "Unpin Panel" : "Pin Panel Open")

            NavIconButton(
                icon: "gearshape",
                isOn: state.showSettings,
                fgMuted: t.fgMute,
                fgActive: t.fg,
                isDark: state.isDark
            ) {
                if state.canTogglePopover("settings") { state.showSettings.toggle() }
            }
            .help("Settings")
            .popover(
                isPresented: Binding(
                    get: { state.showSettings },
                    set: { newValue in
                        if !newValue && state.showSettings { state.notePopoverDismissed("settings") }
                        state.showSettings = newValue
                    }
                ),
                attachmentAnchor: .point(.bottom),
                arrowEdge: .top
            ) {
                SettingsPopoverView(state: state)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 32)
    }

    private var noteCounter: some View {
        let count = state.Notes.isEmpty ? 0 : state.Notes.components(separatedBy: "\n").count
        let atCap = count >= NookState.maxNoteLines
        return Text("\(count)/\(NookState.maxNoteLines)")
            .font(NookType.microMono)
            .foregroundStyle(atCap ? t.dotAttn : t.fgMute)
    }

    // MARK: - Components

    private var dragGrip: some View {
        VStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 4) {
                    Circle().fill(t.fgMute).frame(width: 3, height: 3)
                    Circle().fill(t.fgMute).frame(width: 3, height: 3)
                }
            }
        }
        .frame(width: 20, height: 40)
        .contentShape(Rectangle())
    }

    private var verticalDivider: some View {
        Rectangle()
            .fill(t.stroke1)
            .frame(width: 0.5, height: 20)
    }
}

// MARK: - Nav Trigger Button (icon + label + chevron, with optional trailing accessory)

struct NavTriggerButton: View {
    let icon: String
    let label: String
    let isOn: Bool
    let isDark: Bool
    var trailing: (() -> AnyView)? = nil
    let action: () -> Void

    @State private var isHovered = false
    private var t: NookTheme { NookTheme(isDark: isDark) }

    private var bgFill: Color {
        if isOn      { return t.L3 }
        if isHovered { return t.hoverBg }
        return Color.clear
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(NookType.label)
                    .foregroundStyle(t.fgMid)

                Text(label)
                    .font(NookType.label)
                    .foregroundStyle(t.fgMid)
                    .fixedSize(horizontal: true, vertical: false)

                if let trailing { trailing() }

                Image(systemName: "chevron.down")
                    .font(NookType.chevron)
                    .foregroundStyle(t.fgMute)
                    .rotationEffect(.degrees(isOn ? 180 : 0))
                    .animation(.easeOut(duration: 0.15), value: isOn)
            }
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(
                RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                    .fill(bgFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                            .strokeBorder(isOn ? t.stroke3 : .clear, lineWidth: 0.5)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }
}

// MARK: - Nav Icon Button with hover state

struct NavIconButton: View {
    let icon: String
    let isOn: Bool
    let fgMuted: Color
    let fgActive: Color
    let isDark: Bool
    var tone: NookButtonTone = .normal
    let action: () -> Void

    @State private var isHovered = false
    private var t: NookTheme { NookTheme(isDark: isDark) }

    private var activeBg:        Color { t.L3 }
    private var activeBorder:    Color { t.stroke3 }
    private var activeHighlight: Color { t.innerHighlight }

    private var bgFill: Color {
        switch tone {
        case .cta:    return isHovered ? t.ctaBgHover : t.ctaBg
        case .normal:
            if isOn      { return activeBg }
            if isHovered { return t.hoverBg }
            return Color.clear
        }
    }
    private var fgColor: Color {
        switch tone {
        case .cta:    return t.ctaFg
        case .normal: return (isOn || isHovered) ? fgActive : fgMuted
        }
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: tone == .cta ? 14 : 13, weight: tone == .cta ? .semibold : .medium))
                .foregroundStyle(fgColor)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                        .fill(bgFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                                .strokeBorder(isOn && tone == .normal ? activeBorder : .clear, lineWidth: 0.5)
                        )
                        .overlay(alignment: .top) {
                            if isOn && tone == .normal {
                                RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [activeHighlight, .clear],
                                            startPoint: .top,
                                            endPoint: .center
                                        ),
                                        lineWidth: 0.5
                                    )
                                    .allowsHitTesting(false)
                            }
                        }
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }
}
