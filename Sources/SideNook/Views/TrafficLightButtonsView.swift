// Sources/SideNook/Views/TrafficLightButtonsView.swift
import SwiftUI

struct TrafficLightButtonsView: View {
    @Bindable var state: NookState

    @State private var isHovered = false

    private let m = TrafficLightMetrics.shared

    var body: some View {
        HStack(spacing: m.centerSpacing - m.diameter) {
            trafficDot(
                fill:       state.isWindowActive ? .tlClose       : .tlInactive,
                border:     state.isWindowActive ? .tlCloseBorder  : .tlInactiveBorder,
                glyph:      "xmark",
                glyphColor: .tlCloseGlyph
            ) { state.quitApp() }

            trafficDot(
                fill:       state.isWindowActive ? .tlMinimize       : .tlInactive,
                border:     state.isWindowActive ? .tlMinimizeBorder  : .tlInactiveBorder,
                glyph:      "minus",
                glyphColor: .tlMinimizeGlyph
            ) { state.collapse() }

            trafficDot(
                fill:       state.isWindowActive ? .tlFullscreen       : .tlInactive,
                border:     state.isWindowActive ? .tlFullscreenBorder  : .tlInactiveBorder,
                glyph:      state.isMaximized ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right",
                glyphColor: .tlFullscreenGlyph
            ) { state.toggleMaxMin() }
        }
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovered)
    }

    private func trafficDot(
        fill: Color,
        border: Color,
        glyph: String,
        glyphColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle().fill(fill)
                Circle().strokeBorder(border, lineWidth: 1)
                if isHovered && state.isWindowActive {
                    Image(systemName: glyph)
                        .font(.system(size: m.diameter * 0.52, weight: .bold))
                        .foregroundStyle(glyphColor)
                }
            }
            .frame(width: m.diameter, height: m.diameter)
        }
        .buttonStyle(.plain)
    }
}
