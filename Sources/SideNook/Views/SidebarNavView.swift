// Sources/SideNook/Views/SidebarNavView.swift
import SwiftUI

struct SidebarNavView: View {
    @Bindable var state: NookState

    private var t: NookTheme { state.theme }

    var body: some View {
        VStack(spacing: 0) {
            // ── Drag grip row (with layout toggle) ────
            HStack {
                dragGrip
                Spacer()
                Button(action: { state.tabLayout = .topBar }) {
                    Image(systemName: "rectangle.topthird.inset.filled")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(t.fgMute)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Switch to Top-bar Layout")
                .padding(.trailing, 4)
            }
            .frame(height: 34)
            .frame(maxWidth: .infinity)
            .background(DragHandleView())

            Rectangle().fill(t.stroke1).frame(height: 0.5)

            // ── Action buttons (horizontal row near top) ──
            HStack(spacing: 0) {
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
            .padding(.horizontal, 6)
            .padding(.vertical, 4)

            Rectangle().fill(t.stroke1).frame(height: 0.5)

            // ── Tab list ──────────────────────────────
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 3) {
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

            Rectangle().fill(t.stroke1).frame(height: 0.5)

            Text("SideNook v1.0")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(t.fgMute)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
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

    private var dragGrip: some View {
        VStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 3) {
                    Circle().fill(t.fgMute).frame(width: 3, height: 3)
                    Circle().fill(t.fgMute).frame(width: 3, height: 3)
                }
            }
        }
        .padding(.leading, 10)
    }

    private func sidebarButton(icon: String, isOn: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isOn ? t.fg : t.fgMute)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
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
    @State private var attnOpacity: Double = 1.0

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
        case .live: return Color(red: 0.21, green: 0.82, blue: 0.50)
        case .attn: return Color(red: 0.95, green: 0.71, blue: 0.18)
        case .dead: return .red.opacity(0.5)
        }
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 7, height: 7)
                    .shadow(color: session.status != .dead ? dotColor.opacity(0.53) : .clear, radius: 3)
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
                    .font(.system(size: 12, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(fgColor)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 0)

                if isHovered || isActive {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(isDark ? Color.white.opacity(0.50) : Color.black.opacity(0.45))
                            .frame(width: 14, height: 14)
                            .background(Circle().fill(isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.07)))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.animation(.easeOut(duration: 0.1)))
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, isHovered || isActive ? 4 : 10)
            .frame(height: 30)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(tabBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(isActive ? t.stroke3 : .clear, lineWidth: 0.5)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
        .animation(.easeOut(duration: 0.12), value: isActive)
    }
}
