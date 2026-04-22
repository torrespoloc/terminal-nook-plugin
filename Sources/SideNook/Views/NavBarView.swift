// Sources/SideNook/Views/NavBarView.swift
import SwiftUI

struct NavBarView: View {
    @Bindable var state: NookState

    var body: some View {
        HStack(spacing: 0) {
            // Drag grip
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 16, height: 1.5)
                }
            }
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())

            // Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(state.sessions) { session in
                        TabButtonView(
                            session: session,
                            isActive: session.id == state.activeSessionID,
                            onSelect: { state.switchToSession(session.id) },
                            onClose: { state.closeSession(session.id) }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxWidth: .infinity)

            // New tab button
            Button {
                if state.sessions.count < NookState.maxTabs {
                    state.createSession()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(state.sessions.count >= NookState.maxTabs)

            // Pin button
            Button {
                state.togglePin()
            } label: {
                Image(systemName: state.isPinned ? "pin.fill" : "pin.slash")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(state.isPinned ? Color.white : Color.white.opacity(0.5))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)
        }
        .frame(height: 28)
        .background(DragHandleView())
        .background(Color.white.opacity(0.04))
    }
}
