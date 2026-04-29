// Sources/SideNook/Views/SettingsPopoverView.swift
import SwiftUI

struct SettingsPopoverView: View {
    @Bindable var state: NookState

    private var t: NookTheme { state.theme }
    private var bg: Color { t.aboutBg }
    private var cardBg: Color { t.groupBg }
    private var cardStroke: Color { t.hoverBg }
    private var fg: Color { t.fg }
    private var fgMuted: Color { t.fgMute }
    private var dividerColor: Color { t.stroke1 }
    private var segmentActiveBg: Color { t.pressedBg }

    @State private var showShortcuts = false

    private let accentPresets: [(name: String, hex: String)] = [
        ("Phosphor green", "#35d07f"),
        ("Amber",          "#f0b429"),
        ("Ice",            "#6ec1ff"),
        ("Magenta",        "#e05a9b"),
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
                                .frame(width: 16, height: 16)
                            Text("Accent Color")
                                .font(NookType.formValue)
                                .foregroundStyle(fg)
                        }
                        HStack(spacing: 4) {
                            ForEach(accentPresets, id: \.hex) { preset in
                                accentSwatchButton(hex: preset.hex, name: preset.name)
                            }
                            customAccentSwatch
                        }
                    }
                    .padding(12)
                }

                // ── Group 1: Font Size ────────────────────────
                settingsCard {
                    HStack(spacing: 8) {
                        Image(systemName: "textformat.size")
                            .font(NookType.body)
                            .foregroundStyle(fgMuted)
                            .frame(width: 16)
                        Text("Font Size")
                            .font(NookType.formValue)
                            .foregroundStyle(fg)
                        Spacer()
                        HStack(spacing: 4) {
                            Button(action: { state.zoomOut() }) {
                                Image(systemName: "minus")
                                    .font(NookType.captionBold)
                                    .foregroundStyle(fgMuted)
                                    .frame(width: 20, height: 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                                            .fill(t.groupBg)
                                    )
                            }
                            .buttonStyle(.plain)
                            Text("\(Int(state.fontSize))")
                                .font(NookType.bodyMonoEmph)
                                .foregroundStyle(fg)
                                .frame(width: 26)
                            Button(action: { state.zoomIn() }) {
                                Image(systemName: "plus")
                                    .font(NookType.captionBold)
                                    .foregroundStyle(fgMuted)
                                    .frame(width: 20, height: 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                                            .fill(t.groupBg)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                }

                // ── Group 3: Dock Position + Launch at Login + Reduce Motion ──
                settingsCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.dashed")
                                .font(NookType.body)
                                .foregroundStyle(fgMuted)
                                .frame(width: 16)
                            Text("Dock Position")
                                .font(NookType.formValue)
                                .foregroundStyle(fg)
                        }
                        HStack(spacing: 4) {
                            ForEach(NookState.ScreenEdge.allCases, id: \.rawValue) { edge in
                                Button(action: { state.dockedEdge = edge }) {
                                    Text(edge.rawValue.capitalized)
                                        .font(.system(size: 12, weight: state.dockedEdge == edge ? .semibold : .regular))
                                        .foregroundStyle(state.dockedEdge == edge ? fg : fgMuted)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                                                .fill(state.dockedEdge == edge ? segmentActiveBg : Color.clear)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(12)

                    sectionDivider

                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.circle")
                            .font(NookType.body)
                            .foregroundStyle(fgMuted)
                            .frame(width: 16)
                        Text("Launch at Login")
                            .font(NookType.formValue)
                            .foregroundStyle(fg)
                        Spacer()
                        NookToggle(isOn: Binding(get: { state.launchAtLogin }, set: { state.launchAtLogin = $0 }), theme: t)
                    }
                    .padding(12)

                    sectionDivider

                    HStack(spacing: 8) {
                        Image(systemName: "hand.raised")
                            .font(NookType.body)
                            .foregroundStyle(fgMuted)
                            .frame(width: 16)
                        Text("Reduce Motion")
                            .font(NookType.formValue)
                            .foregroundStyle(fg)
                        Spacer()
                        NookToggle(isOn: $state.reduceMotion, theme: t)
                    }
                    .padding(12)
                }

                // ── Group 4: Shortcuts + About + Quit ─────────
                settingsCard {
                    Button(action: { withAnimation(.easeOut(duration: 0.15)) { showShortcuts.toggle() } }) {
                        HStack(spacing: 8) {
                            Image(systemName: "keyboard")
                                .font(NookType.body)
                                .foregroundStyle(fgMuted)
                                .frame(width: 16)
                            Text("Keyboard Shortcuts")
                                .font(NookType.formValue)
                                .foregroundStyle(fg)
                            Spacer()
                            Image(systemName: showShortcuts ? "chevron.up" : "chevron.down")
                                .font(NookType.captionEmph)
                                .foregroundStyle(fgMuted)
                        }
                        .padding(12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if showShortcuts {
                        ShortcutsListView(isDark: state.isDark)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    sectionDivider

                    settingsRow(icon: "info.circle", label: "About SideNook", showChevron: true) {
                        if state.canTogglePopover("about") { state.showAbout.toggle() }
                    }
                    .popover(
                        isPresented: Binding(
                            get: { state.showAbout },
                            set: { newValue in
                                if !newValue && state.showAbout { state.notePopoverDismissed("about") }
                                state.showAbout = newValue
                            }
                        ),
                        arrowEdge: .leading
                    ) {
                        AboutView(isDark: state.isDark) { state.showAbout = false }
                    }

                    sectionDivider

                    Button(action: { NSApplication.shared.terminate(nil) }) {
                        HStack(spacing: 8) {
                            Image(systemName: "power")
                                .font(NookType.body)
                                .foregroundStyle(t.danger)
                                .frame(width: 16)
                            Text("Quit SideNook")
                                .font(NookType.formValue)
                                .foregroundStyle(t.danger)
                            Spacer()
                            Text("⌘Q")
                                .font(NookType.captionEmph)
                                .foregroundStyle(t.fgMute)
                        }
                        .padding(12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 280)
        .frame(maxHeight: 520)
        .background(bg)
    }

    // MARK: - Helpers

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
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
                    .font(NookType.body)
                    .foregroundStyle(fgMuted)
                    .frame(width: 16)
                Text(label)
                    .font(NookType.formValue)
                    .foregroundStyle(fg)
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(NookType.captionEmph)
                        .foregroundStyle(t.fgMute)
                }
            }
            .padding(12)
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
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                        .fill(isSelected ? segmentActiveBg : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Accent helpers

    private var accentBinding: Binding<Color> {
        Binding(
            get: { Color(hex: state.accentHex) ?? t.defaultAccent },
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
                    RoundedRectangle(cornerRadius: NookRadius.sm, style: .continuous)
                        .strokeBorder(color, lineWidth: 1.5)
                        .frame(width: 40, height: 24)
                    RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                        .strokeBorder(bg, lineWidth: 2)
                        .frame(width: 37, height: 21)
                }
                RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                    .fill(color)
                    .frame(width: 34, height: 18)
                    .overlay(
                        Group {
                            if !isSelected {
                                RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                                    .strokeBorder(t.stroke3, lineWidth: 0.5)
                            }
                        }
                    )
            }
            .frame(width: 40, height: 24)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Accent: \(name)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var customAccentSwatch: some View {
        let currentColor = Color(hex: state.accentHex) ?? t.defaultAccent
        return ZStack {
            // Visual layer — non-interactive
            ZStack {
                if isCustomAccent {
                    RoundedRectangle(cornerRadius: NookRadius.sm, style: .continuous)
                        .strokeBorder(currentColor, lineWidth: 1.5)
                        .frame(width: 40, height: 24)
                    RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                        .strokeBorder(bg, lineWidth: 2)
                        .frame(width: 37, height: 21)
                }
                RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                    .fill(currentColor)
                    .frame(width: 34, height: 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                            .strokeBorder(t.fgMute, style: StrokeStyle(lineWidth: 1.2, dash: [2.5, 2]))
                    )
            }
            .frame(width: 40, height: 24)
            .allowsHitTesting(false)

            // Transparent NSColorWell — provides click-to-open-color-panel
            TransparentColorWell(color: accentBinding)
                .frame(width: 40, height: 24)
                .opacity(0)
        }
        .frame(width: 40, height: 24)
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
