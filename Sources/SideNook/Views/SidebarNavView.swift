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
                SidebarIconButton(icon: "plus", isOn: false, fgMuted: t.fgMute, fgActive: t.fg, isDark: state.isDark) {
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
                    if state.canTogglePopover() { state.showSettings.toggle() }
                }
                .help("Settings")
                .popover(
                    isPresented: Binding(
                        get: { state.showSettings },
                        set: { newValue in
                            if !newValue && state.showSettings { state.notePopoverDismissed() }
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
                    ForEach(state.sessions) { session in
                        SidebarTabRow(
                            session: session,
                            isActive: session.id == state.activeSessionID,
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
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(t.L2)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(t.stroke2, lineWidth: 0.5)
                )
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
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

private struct SidebarIconButton: View {
    let icon: String
    let isOn: Bool
    let fgMuted: Color
    let fgActive: Color
    let isDark: Bool
    let action: () -> Void

    @State private var isHovered = false

    private var hoverBg: Color {
        isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isOn || isHovered ? fgActive : fgMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isHovered ? hoverBg : Color.clear)
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
        case .idle: return .clear
        case .live: return Color(red: 0.21, green: 0.82, blue: 0.50)
        case .attn: return Color(red: 0.95, green: 0.71, blue: 0.18)
        case .dead: return t.fgMute
        }
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {                                    // 8 ✓
                if session.status != .idle {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 8, height: 8)                    // 7 → 8
                        .shadow(color: session.status != .dead ? dotColor.opacity(0.53) : .clear, radius: 4) // 3 → 4
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
                }

                Text(session.title.truncated(to: 22))
                    .font(.system(size: 13, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(fgColor)
                    .fixedSize(horizontal: true, vertical: false)

                Spacer(minLength: 0)

                if isHovered || isActive {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))  // 9 → 8
                            .foregroundStyle(isDark ? Color.white.opacity(0.50) : Color.black.opacity(0.45))
                            .frame(width: 16, height: 16)           // 14 → 16
                            .background(Circle().fill(isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.07)))
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
                RoundedRectangle(cornerRadius: 8, style: .continuous)  // 7 → 8 (on grid)
                    .fill(tabBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(isActive ? t.stroke3 : .clear, lineWidth: 0.5)
                    )
                    .overlay(alignment: .top) {
                        if isActive {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
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
