// Sources/SideNook/Views/SettingsPopoverView.swift
import SwiftUI

struct SettingsPopoverView: View {
    @Bindable var state: NookState

    private var bg: Color {
        state.isDark ? Color(white: 0.14) : Color(white: 0.97)
    }
    private var fg: Color {
        state.isDark ? Color.white.opacity(0.85) : Color.black.opacity(0.85)
    }
    private var fgMuted: Color {
        state.isDark ? Color.white.opacity(0.45) : Color.black.opacity(0.45)
    }
    private var dividerColor: Color {
        state.isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.07)
    }
    private var segmentActiveBg: Color {
        state.isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    @State private var showShortcuts = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Appearance
            settingsRow(
                icon: state.isDark ? "sun.max.fill" : "moon.fill",
                label: state.isDark ? "Light Mode" : "Dark Mode"
            ) {
                state.toggleAppearance()
            }

            sectionDivider

            // Tab Layout
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(fgMuted)
                        .frame(width: 18)
                    Text("Tab Layout")
                        .font(.system(size: 14))
                        .foregroundStyle(fg)
                }

                HStack(spacing: 4) {
                    layoutButton(label: "Sidebar", value: .leftSidebar)
                    layoutButton(label: "Top Bar", value: .topBar)
                }
                .padding(.leading, 26)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            sectionDivider

            // Pin on Top
            HStack(spacing: 8) {
                Image(systemName: state.isPinned ? "pin.fill" : "pin.slash")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(fgMuted)
                    .frame(width: 18)
                Text("Pin on Top")
                    .font(.system(size: 14))
                    .foregroundStyle(fg)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { state.isPinned },
                    set: { state.isPinned = $0 }
                ))
                .toggleStyle(.switch)
                .scaleEffect(0.75)
                .frame(width: 44)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            sectionDivider

            // Font Size
            HStack(spacing: 8) {
                Image(systemName: "textformat.size")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(fgMuted)
                    .frame(width: 18)
                Text("Font Size")
                    .font(.system(size: 14))
                    .foregroundStyle(fg)
                Spacer()
                HStack(spacing: 4) {
                    Button(action: { state.zoomOut() }) {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(fgMuted)
                            .frame(width: 24, height: 24)
                            .background(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(state.isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                            )
                    }
                    .buttonStyle(.plain)

                    Text("\(Int(state.fontSize))")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(fg)
                        .frame(width: 26)

                    Button(action: { state.zoomIn() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(fgMuted)
                            .frame(width: 24, height: 24)
                            .background(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(state.isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            sectionDivider

            // Dock Position
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.dashed")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(fgMuted)
                        .frame(width: 18)
                    Text("Dock Position")
                        .font(.system(size: 14))
                        .foregroundStyle(fg)
                }

                HStack(spacing: 4) {
                    ForEach(NookState.ScreenEdge.allCases, id: \.rawValue) { edge in
                        Button(action: { state.dockedEdge = edge }) {
                            Text(edge.rawValue.capitalized)
                                .font(.system(size: 12, weight: state.dockedEdge == edge ? .semibold : .regular))
                                .foregroundStyle(state.dockedEdge == edge ? fg : fgMuted)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(state.dockedEdge == edge ? segmentActiveBg : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 26)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            sectionDivider

            // Launch at Login
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.circle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(fgMuted)
                    .frame(width: 18)
                Text("Launch at Login")
                    .font(.system(size: 14))
                    .foregroundStyle(fg)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { state.launchAtLogin },
                    set: { state.launchAtLogin = $0 }
                ))
                .toggleStyle(.switch)
                .scaleEffect(0.75)
                .frame(width: 44)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            sectionDivider

            // Keyboard Shortcuts (expandable)
            Button(action: { withAnimation(.easeOut(duration: 0.15)) { showShortcuts.toggle() } }) {
                HStack(spacing: 8) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(fgMuted)
                        .frame(width: 18)
                    Text("Keyboard Shortcuts")
                        .font(.system(size: 14))
                        .foregroundStyle(fg)
                    Spacer()
                    Image(systemName: showShortcuts ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(fgMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showShortcuts {
                ShortcutsListView(isDark: state.isDark)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            sectionDivider

            // About — opens as sibling popover to the left
            settingsRow(icon: "info.circle", label: "About SideNook") {
                state.showAbout = true
            }

            sectionDivider

            // Quit
            Button(action: { NSApplication.shared.terminate(nil) }) {
                HStack(spacing: 8) {
                    Image(systemName: "power")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.red.opacity(0.70))
                        .frame(width: 18)
                    Text("Quit SideNook")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.red.opacity(0.80))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(width: 260)
        .background(bg)
        .popover(
            isPresented: Binding(get: { state.showAbout }, set: { state.showAbout = $0 }),
            arrowEdge: .leading
        ) {
            AboutView(isDark: state.isDark) { state.showAbout = false }
        }
    }

    // MARK: - Helpers

    private var sectionDivider: some View {
        Rectangle()
            .fill(dividerColor)
            .frame(height: 0.5)
            .padding(.horizontal, 8)
    }

    private func settingsRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(fgMuted)
                    .frame(width: 18)
                Text(label)
                    .font(.system(size: 14))
                    .foregroundStyle(fg)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func layoutButton(label: String, value: NookState.TabLayout) -> some View {
        let isSelected = state.tabLayout == value
        return Button(action: { state.tabLayout = value }) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? fg : fgMuted)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(isSelected ? segmentActiveBg : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}
