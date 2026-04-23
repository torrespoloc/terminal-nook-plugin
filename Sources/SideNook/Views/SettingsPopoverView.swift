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

            // Pin on Top
            HStack(spacing: 8) {
                Image(systemName: state.isPinned ? "pin.fill" : "pin.slash")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(fgMuted)
                    .frame(width: 18)
                Text("Pin on Top")
                    .font(.system(size: 12))
                    .foregroundStyle(fg)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { state.isPinned },
                    set: { state.isPinned = $0 }
                ))
                .toggleStyle(.switch)
                .scaleEffect(0.7)
                .frame(width: 40)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            sectionDivider

            // Font Size
            HStack(spacing: 8) {
                Image(systemName: "textformat.size")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(fgMuted)
                    .frame(width: 18)
                Text("Font Size")
                    .font(.system(size: 12))
                    .foregroundStyle(fg)
                Spacer()
                HStack(spacing: 4) {
                    Button(action: { state.zoomOut() }) {
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(fgMuted)
                            .frame(width: 22, height: 22)
                            .background(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(state.isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                            )
                    }
                    .buttonStyle(.plain)

                    Text("\(Int(state.fontSize))")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(fg)
                        .frame(width: 24)

                    Button(action: { state.zoomIn() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(fgMuted)
                            .frame(width: 22, height: 22)
                            .background(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(state.isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            sectionDivider

            // Default Position
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.dashed")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(fgMuted)
                        .frame(width: 18)
                    Text("Dock Position")
                        .font(.system(size: 12))
                        .foregroundStyle(fg)
                }

                HStack(spacing: 4) {
                    ForEach(NookState.ScreenEdge.allCases, id: \.rawValue) { edge in
                        Button(action: { state.dockedEdge = edge }) {
                            Text(edge.rawValue.capitalized)
                                .font(.system(size: 10, weight: state.dockedEdge == edge ? .semibold : .regular))
                                .foregroundStyle(state.dockedEdge == edge ? fg : fgMuted)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(state.dockedEdge == edge
                                              ? (state.isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.07))
                                              : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 26)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            sectionDivider

            // Keyboard Shortcuts (expandable)
            Button(action: { withAnimation(.easeOut(duration: 0.15)) { showShortcuts.toggle() } }) {
                HStack(spacing: 8) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(fgMuted)
                        .frame(width: 18)
                    Text("Keyboard Shortcuts")
                        .font(.system(size: 12))
                        .foregroundStyle(fg)
                    Spacer()
                    Image(systemName: showShortcuts ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(fgMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showShortcuts {
                ShortcutsListView(isDark: state.isDark)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            sectionDivider

            // About
            settingsRow(icon: "info.circle", label: "About SideNook") {
                state.showSettings = false
                state.showAbout = true
            }
        }
        .frame(width: 250)
        .background(bg)
    }

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
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(fgMuted)
                    .frame(width: 18)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(fg)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
