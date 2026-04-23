// Sources/SideNook/Views/TerminalContainerView.swift
import SwiftUI

/// Hosts the active terminal session with matched inner radius.
/// Overlays a transparent input-highlight layer that paints baby-blue bands
/// behind rows where the user submitted input.
struct TerminalContainerView: View {
    let session: TerminalSession
    let isDark: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                TerminalSessionView(session: session, containerSize: geo.size)
                    .id(session.id)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                InputHighlightView(session: session, isDark: isDark, containerSize: geo.size)
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}
