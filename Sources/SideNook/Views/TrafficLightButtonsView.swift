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
            ) { state.collapse() }

            trafficDot(
                fill:       state.isWindowActive ? .tlMinimize       : .tlInactive,
                border:     state.isWindowActive ? .tlMinimizeBorder  : .tlInactiveBorder,
                glyph:      "minus",
                glyphColor: .tlMinimizeGlyph
            ) { state.togglePin() }

            trafficDot(
                fill:       state.isWindowActive ? .tlFullscreen       : .tlInactive,
                border:     state.isWindowActive ? .tlFullscreenBorder  : .tlInactiveBorder,
                glyph:      "arrow.up.left.and.arrow.down.right",
                glyphColor: .tlFullscreenGlyph
            ) {
                state.tabLayout = (state.tabLayout == .topBar) ? .leftSidebar : .topBar
            }
        }
        .onHover { isHovered = $0 }
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
