// Sources/SideNook/Views/NavBarView.swift
import SwiftUI

struct NavBarView: View {
    @Bindable var state: NookState

    // MARK: - Palette

    private var surfaceBg: Color {
        state.isDark
            ? Color.white.opacity(0.05)
            : Color.black.opacity(0.04)
    }
    private var dividerColor: Color {
        state.isDark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.07)
    }
    private var fgMuted: Color {
        state.isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.40)
    }
    private var fgActive: Color {
        state.isDark ? Color.white.opacity(0.85) : Color.black.opacity(0.85)
    }
    private var gripDot: Color {
        state.isDark ? Color.white.opacity(0.15) : Color.black.opacity(0.15)
    }
    private var titleColor: Color {
        state.isDark ? Color.white.opacity(0.55) : Color.black.opacity(0.50)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // ── Drag grip ──────────────────────────────
                dragGrip
                    .padding(.leading, 10)
                    .padding(.trailing, 6)

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
                        }
                    }
                    .padding(.horizontal, 6)
                }
                .frame(maxWidth: .infinity)

                // ── Thin divider ──────────────────────────
                verticalDivider

                // ── Action buttons ───────────────────────
                HStack(spacing: 2) {
                    navButton(icon: "plus", isOn: false) {
                        if state.sessions.count < NookState.maxTabs {
                            state.createSession()
                        }
                    }
                    .help("New Tab")
                    navButton(
                        icon: state.isDark ? "sun.max.fill" : "moon.fill",
                        isOn: false
                    ) {
                        state.toggleAppearance()
                    }
                    .help(state.isDark ? "Switch to Light Mode" : "Switch to Dark Mode")
                    navButton(
                        icon: state.isPinned ? "pin.fill" : "pin.slash",
                        isOn: state.isPinned
                    ) {
                        state.togglePin()
                    }
                    .help(state.isPinned ? "Unpin Panel" : "Pin Panel Open")
                    navButton(
                        icon: "gearshape",
                        isOn: state.showSettings
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
                .padding(.horizontal, 8)
            }
            .frame(height: 40)
            .background(DragHandleView())
            .background(surfaceBg)

            // Bottom edge line separating nav from terminal
            Rectangle()
                .fill(dividerColor)
                .frame(height: 0.5)
        }
    }

    // MARK: - Components

    private var dragGrip: some View {
        VStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 3) {
                    Circle().fill(gripDot).frame(width: 3, height: 3)
                    Circle().fill(gripDot).frame(width: 3, height: 3)
                }
            }
        }
        .frame(width: 20, height: 40)
        .contentShape(Rectangle())
    }

    private var verticalDivider: some View {
        Rectangle()
            .fill(dividerColor)
            .frame(width: 0.5, height: 28)
    }

    private func navButton(icon: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        NavIconButton(
            icon: icon,
            isOn: isOn,
            fgMuted: fgMuted,
            fgActive: fgActive,
            isDark: state.isDark,
            action: action
        )
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

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isOn ? fgActive : (isHovered ? fgActive : fgMuted))
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isHovered ? hoverBg : Color.clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
