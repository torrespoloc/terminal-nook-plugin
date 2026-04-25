// Sources/SideNook/Views/SettingsPopoverView.swift
import SwiftUI

struct SettingsPopoverView: View {
    @Bindable var state: NookState

    private var bg: Color {
        state.isDark ? NookTheme.darkL3 : Color(white: 0.97)
    }
    private var cardBg: Color {
        // rgba(0,0,0,0.15) over L3 per spec — darkens group rows inside the popover
        state.isDark ? Color.black.opacity(0.15) : Color.white.opacity(0.70)
    }
    private var cardStroke: Color {
        state.isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.07)
    }
    private var t: NookTheme { state.theme }
    private var fg: Color { t.fg }
    private var fgMuted: Color { t.fgMute }
    private var dividerColor: Color { t.stroke1 }
    private var segmentActiveBg: Color {
        state.isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.08)
    }

    @State private var showShortcuts = false

    private let accentPresets: [(name: String, hex: String)] = [
        ("Phosphor green", "#35d07f"),
        ("Amber",          "#f0b429"),
        ("Ice",            "#6ec1ff"),
        ("Magenta",        "#e05a9b"),
        ("Classic",        "#4ade80"),
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {

                // ── Group 0: Accent Color ─────────────────────
                settingsCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(t.accent)
                                .frame(width: 14, height: 14)
                                .frame(width: 18, height: 18)
                            Text("Accent Color")
                                .font(.system(size: 14))
                                .foregroundStyle(fg)
                        }
                        HStack(spacing: 6) {
                            ForEach(accentPresets, id: \.hex) { preset in
                                accentSwatchButton(hex: preset.hex, name: preset.name)
                            }
                            customAccentSwatch
                        }
                        .padding(.leading, 26)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }

                // ── Group 1: Font Size ────────────────────────
                settingsCard {
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
                                    .frame(width: 20, height: 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(state.isDark ? Color.black.opacity(0.30) : Color.black.opacity(0.05))
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
                                    .frame(width: 20, height: 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(state.isDark ? Color.black.opacity(0.30) : Color.black.opacity(0.05))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }

                // ── Group 3: Dock Position + Launch at Login + Reduce Motion ──
                settingsCard {
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
                                        .frame(maxWidth: .infinity)
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

                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(fgMuted)
                            .frame(width: 18)
                        Text("Launch at Login")
                            .font(.system(size: 14))
                            .foregroundStyle(fg)
                        Spacer()
                        NookToggle(isOn: Binding(get: { state.launchAtLogin }, set: { state.launchAtLogin = $0 }), theme: t)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                    sectionDivider

                    HStack(spacing: 8) {
                        Image(systemName: "hand.raised")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(fgMuted)
                            .frame(width: 18)
                        Text("Reduce Motion")
                            .font(.system(size: 14))
                            .foregroundStyle(fg)
                        Spacer()
                        NookToggle(isOn: $state.reduceMotion, theme: t)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }

                // ── Group 4: Shortcuts + About + Quit ─────────
                settingsCard {
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
                                .font(.system(size: 11, weight: .medium))
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

                    settingsRow(icon: "info.circle", label: "About SideNook", showChevron: true) {
                        state.showAbout = true
                    }

                    sectionDivider

                    Button(action: { NSApplication.shared.terminate(nil) }) {
                        HStack(spacing: 8) {
                            Image(systemName: "power")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(t.danger)
                                .frame(width: 18)
                            Text("Quit SideNook")
                                .font(.system(size: 14))
                                .foregroundStyle(t.danger)
                            Spacer()
                            Text("⌘Q")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(t.fgMute)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
        }
        .frame(width: 260)
        .frame(maxHeight: 520)
        .background(bg)
        .popover(
            isPresented: Binding(get: { state.showAbout }, set: { state.showAbout = $0 }),
            arrowEdge: .leading
        ) {
            AboutView(isDark: state.isDark) { state.showAbout = false }
        }
    }

    // MARK: - Helpers

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(cardStroke, lineWidth: 0.5)
                )
        )
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(dividerColor)
            .frame(height: 0.5)
            .padding(.horizontal, 8)
    }

    private func settingsRow(icon: String, label: String, showChevron: Bool = false, action: @escaping () -> Void) -> some View {
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
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(t.fgMute)
                }
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

    // MARK: - Accent helpers

    private var accentBinding: Binding<Color> {
        Binding(
            get: { Color(hex: state.accentHex) ?? Color(red: 0.208, green: 0.816, blue: 0.498) },
            set: { state.accentHex = $0.hexString() ?? "#35d07f" }
        )
    }

    private var isCustomAccent: Bool {
        !accentPresets.contains { $0.hex == state.accentHex }
    }

    private func accentSwatchButton(hex: String, name: String) -> some View {
        let color = Color(hex: hex) ?? .green
        let isSelected = state.accentHex == hex
        return Button(action: { state.accentHex = hex }) {
            ZStack {
                if isSelected {
                    Circle()
                        .strokeBorder(color, lineWidth: 1.5)
                        .frame(width: 30, height: 30)
                    Circle()
                        .strokeBorder(t.L0, lineWidth: 2)
                        .frame(width: 27, height: 27)
                }
                Circle()
                    .fill(color)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Group {
                            if !isSelected {
                                Circle().strokeBorder(t.stroke3, lineWidth: 1)
                            }
                        }
                    )
            }
            .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Accent: \(name)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var customAccentSwatch: some View {
        let currentColor = Color(hex: state.accentHex) ?? Color(red: 0.208, green: 0.816, blue: 0.498)
        return ZStack {
            // Visual layer — non-interactive
            ZStack {
                if isCustomAccent {
                    Circle()
                        .strokeBorder(currentColor, lineWidth: 1.5)
                        .frame(width: 30, height: 30)
                    Circle()
                        .strokeBorder(t.L0, lineWidth: 2)
                        .frame(width: 27, height: 27)
                }
                Circle()
                    .fill(currentColor)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .strokeBorder(t.fgMute, style: StrokeStyle(lineWidth: 1.2, dash: [2.5, 2]))
                    )
            }
            .frame(width: 30, height: 30)
            .allowsHitTesting(false)

            // Transparent NSColorWell — provides click-to-open-color-panel
            TransparentColorWell(color: accentBinding)
                .frame(width: 30, height: 30)
                .opacity(0)
        }
        .frame(width: 30, height: 30)
        .accessibilityLabel("Accent: Custom color")
        .accessibilityAddTraits(isCustomAccent ? .isSelected : [])
    }
}

// MARK: - Transparent NSColorWell wrapper
private struct TransparentColorWell: NSViewRepresentable {
    @Binding var color: Color

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSColorWell {
        let well = NSColorWell(style: .minimal)
        well.isBordered = false
        well.target = context.coordinator
        well.action = #selector(Coordinator.colorChanged(_:))
        return well
    }

    func updateNSView(_ well: NSColorWell, context: Context) {
        context.coordinator.parent = self
        if let srgb = NSColor(color).usingColorSpace(.sRGB) {
            well.color = srgb
        }
    }

    final class Coordinator: NSObject {
        var parent: TransparentColorWell
        init(_ p: TransparentColorWell) { parent = p }
        @MainActor @objc func colorChanged(_ sender: NSColorWell) {
            parent.color = Color(sender.color)
        }
    }
}
