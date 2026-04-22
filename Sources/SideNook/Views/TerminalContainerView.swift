// Sources/SideNook/Views/TerminalContainerView.swift
import SwiftUI

/// Hosts the active terminal session with appropriate clipping.
struct TerminalContainerView: View {
    let session: TerminalSession

    var body: some View {
        TerminalSessionView(session: session)
            .id(session.id)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
