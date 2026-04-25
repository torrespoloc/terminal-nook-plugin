// Sources/SideNook/Views/NavBarView.swift
import SwiftUI

struct NavBarView: View {
    @Bindable var state: NookState

    private var t: NookTheme { state.theme }

    var body: some View {
        HStack(spacing: 0) {
            // ── Drag grip ──────────────────────────────
            dragGrip
                .padding(.leading, 10)
                .padding(.trailing, 4)

            // ── Thin divider ──────────────────────────
            verticalDivider

            // ── Layout toggle (moves panel to sidebar) ─
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
            .padding(.horizontal, 2)

            // ── Thin divider ──────────────────────────
            verticalDivider

            // ── Tabs ─────────────────────────────────
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(state.sessions) { session in
                        TabButtonView(
                            session: session,
                            isActive: session.id == state.activeSessionID,
                            isDark: state.isDark,
                            onSelect: { state.switchToSession(session.id) },
                            onClose: { state.closeSession(session.id) }
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

            // ── Thin divider ──────────────────────────
            verticalDivider

            // ── Action buttons ───────────────────────
            HStack(spacing: 2) {
                NavIconButton(icon: "plus", isOn: false, fgMuted: t.fgMute, fgActive: t.fg, isDark: state.isDark) {
                    if state.sessions.count < NookState.maxTabs {
                        state.createSession()
                    }
                }
                .help("New Tab")

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
                    state.showSettings.toggle()
                }
                .help("Settings")
                .popover(
                    isPresented: Binding(
                        get: { state.showSettings },
                        set: { state.showSettings = $0 }
                    ),
                    arrowEdge: .bottom
                ) {
                    SettingsPopoverView(state: state)
                }

            }
            .padding(.horizontal, 6)
        }
        .frame(height: 40)
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
                .shadow(color: .black.opacity(0.50), radius: 2, y: 1)
        )
        .background(DragHandleView())
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 6, trailing: 8))
    }

    // MARK: - Components

    private var dragGrip: some View {
        VStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 3) {
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

// MARK: - Nav Icon Button with hover state

struct NavIconButton: View {
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

    private var activeBg: Color {
        isDark ? Color(red: 0.149, green: 0.165, blue: 0.239) : Color.white.opacity(0.95)
    }

    private var activeBorder: Color {
        isDark ? Color.white.opacity(0.14) : Color.black.opacity(0.12)
    }

    private var activeHighlight: Color {
        isDark ? Color.white.opacity(0.06) : Color.white.opacity(0.90)
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isOn ? fgActive : (isHovered ? fgActive : fgMuted))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isOn ? activeBg : (isHovered ? hoverBg : Color.clear))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(isOn ? activeBorder : .clear, lineWidth: 0.5)
                        )
                        .overlay(alignment: .top) {
                            if isOn {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
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
    }
}
