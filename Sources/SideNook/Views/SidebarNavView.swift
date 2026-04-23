// Sources/SideNook/Views/SidebarNavView.swift
import SwiftUI

struct SidebarNavView: View {
    @Bindable var state: NookState

    private var bg: Color {
        state.isDark ? Color.white.opacity(0.04) : Color.black.opacity(0.02)
    }
    private var dividerColor: Color {
        state.isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.07)
    }
    private var gripDot: Color {
        state.isDark ? Color.white.opacity(0.16) : Color.black.opacity(0.14)
    }
    private var fgMuted: Color {
        state.isDark ? Color.white.opacity(0.40) : Color.black.opacity(0.40)
    }
    private var fgActive: Color {
        state.isDark ? Color.white.opacity(0.85) : Color.black.opacity(0.85)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag grip
            dragGrip
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .background(DragHandleView())
                .background(bg)

            Rectangle().fill(dividerColor).frame(height: 0.5)

            // Tab list
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 2) {
                    ForEach(state.sessions) { session in
                        SidebarTabRow(
                            session: session,
                            isActive: session.id == state.activeSessionID,
                            isDark: state.isDark,
                            onSelect: { state.switchToSession(session.id) },
                            onClose: { state.closeSession(session.id) }
                        )
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
            }

            Spacer(minLength: 0)

            Rectangle().fill(dividerColor).frame(height: 0.5)

            // Action buttons
            VStack(spacing: 0) {
                sidebarButton(icon: "plus") {
                    if state.sessions.count < NookState.maxTabs { state.createSession() }
                }
                .help("New Tab")

                sidebarButton(icon: state.isDark ? "sun.max.fill" : "moon.fill") {
                    state.toggleAppearance()
                }
                .help(state.isDark ? "Switch to Light Mode" : "Switch to Dark Mode")

                sidebarButton(icon: state.isPinned ? "pin.fill" : "pin.slash", isOn: state.isPinned) {
                    state.togglePin()
                }
                .help(state.isPinned ? "Unpin Panel" : "Pin Panel Open")

                sidebarButton(icon: "gearshape", isOn: state.showSettings) {
                    state.showSettings.toggle()
                }
                .help("Settings")
                .popover(
                    isPresented: Binding(get: { state.showSettings }, set: { state.showSettings = $0 }),
                    arrowEdge: .trailing
                ) {
                    SettingsPopoverView(state: state)
                }
            }
            .padding(.bottom, 8)
        }
        .frame(width: 128)
        .background(bg)
    }

    private var dragGrip: some View {
        VStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 3) {
                    Circle().fill(gripDot).frame(width: 3, height: 3)
                    Circle().fill(gripDot).frame(width: 3, height: 3)
                }
            }
        }
    }

    private func sidebarButton(icon: String, isOn: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isOn ? fgActive : fgMuted)
                .frame(width: 34, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sidebar Tab Row

private struct SidebarTabRow: View {
    let session: TerminalSession
    let isActive: Bool
    let isDark: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovered = false

    private var fgColor: Color {
        if isActive  { return isDark ? Color.white.opacity(0.90) : Color.black.opacity(0.85) }
        if isHovered { return isDark ? Color.white.opacity(0.70) : Color.black.opacity(0.65) }
        return isDark ? Color.white.opacity(0.45) : Color.black.opacity(0.42)
    }
    private var tabBg: Color {
        if isActive  { return isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.06) }
        if isHovered { return isDark ? Color.white.opacity(0.05) : Color.black.opacity(0.03) }
        return Color.clear
    }
    private var accentBar: Color {
        isDark ? Color.white.opacity(0.55) : Color.black.opacity(0.30)
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 5) {
                // Active accent bar
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .fill(isActive ? accentBar : Color.clear)
                    .frame(width: 2, height: 14)

                // Status dot
                Circle()
                    .fill(session.isAlive ? Color.green.opacity(0.55) : Color.red.opacity(0.45))
                    .frame(width: 5, height: 5)

                Text(session.title)
                    .font(.system(size: 13, weight: isActive ? .medium : .regular))
                    .foregroundStyle(fgColor)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 0)

                if isHovered || isActive {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(isDark ? Color.white.opacity(0.50) : Color.black.opacity(0.45))
                            .frame(width: 16, height: 16)
                            .background(Circle().fill(isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.07)))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.animation(.easeOut(duration: 0.1)))
                }
            }
            .padding(.leading, 2)
            .padding(.trailing, isHovered || isActive ? 4 : 8)
            .frame(height: 30)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(tabBg))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .animation(.easeOut(duration: 0.12), value: isActive)
    }
}
