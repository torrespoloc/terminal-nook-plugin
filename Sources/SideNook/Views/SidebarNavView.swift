// Sources/SideNook/Views/SidebarNavView.swift
import SwiftUI

struct SidebarNavView: View {
    @Bindable var state: NookState

    private var t: NookTheme { state.theme }

    var body: some View {
        VStack(spacing: 0) {
            // ── Traffic lights + layout toggle row ────
            HStack {
                TrafficLightButtonsView(state: state)
                    .padding(.leading, 8)
                Spacer()
                NavIconButton(
                    icon: "rectangle.topthird.inset.filled",
                    isOn: false,
                    fgMuted: t.fgMute,
                    fgActive: t.fg,
                    isDark: state.isDark
                ) {
                    state.tabLayout = .topBar
                }
                .help("Switch to Top-bar Layout")
                .padding(.trailing, 4)
            }
            .frame(height: 32)                                      // 34 → 32
            .frame(maxWidth: .infinity)
            .background(DragHandleView())

            Rectangle().fill(t.stroke1).frame(height: 0.5)

            // ── Action buttons (horizontal row near top) ──
            HStack(spacing: 0) {
                SidebarIconButton(icon: "plus", isOn: false, fgMuted: t.fgMute, fgActive: t.fg, isDark: state.isDark, tone: .cta) {
                    if state.sessions.count < NookState.maxTabs { state.createSession() }
                }
                .help("New Tab")

                SidebarIconButton(icon: state.isDark ? "sun.max.fill" : "moon.fill", isOn: false, fgMuted: t.fgMute, fgActive: t.fg, isDark: state.isDark) {
                    state.toggleAppearance()
                }
                .help(state.isDark ? "Switch to Light Mode" : "Switch to Dark Mode")

                SidebarIconButton(icon: state.isPinned ? "pin.fill" : "pin.slash", isOn: state.isPinned, fgMuted: t.fgMute, fgActive: t.fg, isDark: state.isDark) {
                    state.togglePin()
                }
                .help(state.isPinned ? "Unpin Panel" : "Pin Panel Open")

                SidebarIconButton(icon: "gearshape", isOn: state.showSettings, fgMuted: t.fgMute, fgActive: t.fg, isDark: state.isDark) {
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
                    attachmentAnchor: .point(.topTrailing),
                    arrowEdge: .trailing
                ) {
                    SettingsPopoverView(state: state)
                }
            }
            .padding(.horizontal, 8)                                // 6 → 8
            .padding(.vertical, 4)                                  // 4 ✓

            Rectangle().fill(t.stroke1).frame(height: 0.5)

            // ── Tab list ──────────────────────────────
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 4) {                                // 3 → 4
                    if state.notesTabActive {
                        NotesTabRow(
                            isDark: state.isDark,
                            onClose: { state.closeNotesTab() }
                        )
                    }
                    if state.helpTabActive {
                        HelpTabRow(
                            isDark: state.isDark,
                            onClose: { state.closeHelpTab() }
                        )
                    }
                    ForEach(state.sessions) { session in
                        SidebarTabRow(
                            session: session,
                            isActive: session.id == state.activeSessionID && !state.notesTabActive && !state.helpTabActive,
                            isDark: state.isDark,
                            onSelect: { state.switchToSession(session.id) },
                            onClose: { state.closeSession(session.id) },
                            onRename: { session.title = $0 }
                        )
                    }
                }
                .padding(.horizontal, 8)                            // 6 → 8
                .padding(.vertical, 8)                              // 6 → 8
            }

            NotesView(state: state)
                .zIndex(1)

            Rectangle().fill(t.stroke1).frame(height: 0.5)

            CommandLineHelpView(state: state)
                .zIndex(1)

            Rectangle().fill(t.stroke1).frame(height: 0.5)

            Text("SideNook v1.0")
                .font(.system(size: 12, design: .monospaced))      // 12 ✓ (min label size)
                .foregroundStyle(t.fgMute)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)                           // 12 ✓
                .padding(.vertical, 8)                              // 7 → 8
        }
        .frame(width: 180)
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
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
        )
    }

}

// MARK: - Sidebar Icon Button

enum NookButtonTone { case normal, cta }

private struct SidebarIconButton: View {
    let icon: String
    let isOn: Bool
    let fgMuted: Color
    let fgActive: Color
    let isDark: Bool
    var tone: NookButtonTone = .normal
    let action: () -> Void

    @State private var isHovered = false
    private var t: NookTheme { NookTheme(isDark: isDark) }

    private var bgFill: Color {
        switch tone {
        case .cta:    return isHovered ? t.ctaBgHover : t.ctaBg
        case .normal: return isHovered ? t.hoverBg : Color.clear
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
                .font(.system(size: tone == .cta ? 16 : 14, weight: tone == .cta ? .semibold : .medium))
                .foregroundStyle(fgColor)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(
                    RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                        .fill(bgFill)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }
}

// MARK: - Sidebar Tab Row

private struct SidebarTabRow: View {
    let session: TerminalSession
    let isActive: Bool
    let isDark: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    let onRename: (String) -> Void

    @State private var isHovered = false
    @State private var attnOpacity: Double = 1.0
    @State private var isRenaming = false
    @State private var renameText = ""

    private var t: NookTheme { NookTheme(isDark: isDark) }

    private var fgColor: Color {
        if isActive { return t.fg }
        return t.fgMid
    }

    private var tabBg: Color {
        if isActive  { return t.L3 }
        if isHovered { return t.L1 }
        return Color.clear
    }

    private var dotColor: Color {
        switch session.status {
        case .idle: return t.dotIdle
        case .live: return t.dotLive
        case .attn: return t.dotAttn
        case .dead: return t.fgMute
        }
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {                                    // 8 ✓
                Circle()
                    .fill(dotColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: (session.status == .idle || session.status == .dead) ? .clear : dotColor.opacity(0.53), radius: 4)
                    .opacity(session.status == .attn ? attnOpacity : 1)
                    .onAppear {
                        if session.status == .attn {
                            withAnimation(.easeInOut(duration: 0.55).repeatForever()) {
                                attnOpacity = 0.25
                            }
                        }
                    }
                    .onChange(of: session.status) { _, newStatus in
                        if newStatus == .attn {
                            withAnimation(.easeInOut(duration: 0.55).repeatForever()) {
                                attnOpacity = 0.25
                            }
                        } else {
                            withAnimation { attnOpacity = 1 }
                        }
                    }

                Text(session.title)
                    .font(.system(size: 13, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(fgColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isHovered || isActive {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(NookType.pip)  // 9 → 8
                            .foregroundStyle(t.iconFgMute)
                            .frame(width: 16, height: 16)
                            .background(Circle().fill(t.hoverBg))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.animation(.easeOut(duration: 0.1)))
                }
            }
            .padding(.leading, 8)                                   // 10 → 8
            .padding(.trailing, isHovered || isActive ? 4 : 8)     // trailing inactive: 10 → 8
            .frame(height: 32)                                      // 30 → 32
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)  // 7 → 8 (on grid)
                    .fill(tabBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                            .strokeBorder(isActive ? t.stroke3 : .clear, lineWidth: 0.5)
                    )
                    .overlay(alignment: .top) {
                        if isActive {
                            RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
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
                    }
                    .shadow(color: (isActive && isDark) ? .black.opacity(0.35) : .clear, radius: isActive ? 2 : 0, y: isActive ? 1 : 0)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .animation(.easeOut(duration: 0.12), value: isActive)
        .contextMenu {
            Button("Rename Tab") {
                renameText = session.title
                isRenaming = true
            }
            Divider()
            Button("Close Tab", role: .destructive, action: onClose)
        }
        .alert("Rename Tab", isPresented: $isRenaming) {
            TextField("Tab name", text: $renameText)
            Button("Rename") {
                let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { onRename(trimmed) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}


// MARK: - Help Tab Row (sidebar layout)

struct HelpTabRow: View {
    let isDark: Bool
    let onClose: () -> Void

    @State private var isHovered = false
    private var t: NookTheme { NookTheme(isDark: isDark) }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(NookType.captionEmph)
                .foregroundStyle(t.fg)
                .frame(width: 8, height: 8)

            Text("CL Help")
                .font(NookType.bodyEmph)
                .foregroundStyle(t.fg)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(NookType.pip)
                    .foregroundStyle(t.iconFgMute)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(t.hoverBg))
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 8)
        .padding(.trailing, 4)
        .frame(height: 32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                .fill(t.L3)
                .overlay(
                    RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                        .strokeBorder(t.stroke3, lineWidth: 0.5)
                )
                .shadow(color: isDark ? .black.opacity(0.35) : .clear, radius: 2, y: 1)
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}

// MARK: - Notes Tab Row (sidebar layout)

struct NotesTabRow: View {
    let isDark: Bool
    let onClose: () -> Void

    @State private var isHovered = false
    private var t: NookTheme { NookTheme(isDark: isDark) }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "note.text")
                .font(NookType.captionEmph)
                .foregroundStyle(t.fg)
                .frame(width: 8, height: 8)

            Text("My Notes")
                .font(NookType.bodyEmph)
                .foregroundStyle(t.fg)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(NookType.pip)
                    .foregroundStyle(t.iconFgMute)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(t.hoverBg))
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 8)
        .padding(.trailing, 4)
        .frame(height: 32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                .fill(t.L3)
                .overlay(
                    RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                        .strokeBorder(t.stroke3, lineWidth: 0.5)
                )
                .shadow(color: isDark ? .black.opacity(0.35) : .clear, radius: 2, y: 1)
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}
