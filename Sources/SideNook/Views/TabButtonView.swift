// Sources/SideNook/Views/TabButtonView.swift
import SwiftUI

struct TabButtonView: View {
    let session: TerminalSession
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 4) {
                Text(session.title)
                    .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? Color.white : Color.white.opacity(0.6))
                    .lineLimit(1)
                    .truncationMode(.tail)

                if isHovered {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .frame(width: 14, height: 14)
                            .background(Color.white.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 24)
            .frame(maxWidth: 140)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isActive ? Color.white.opacity(0.12) : Color.clear)
            )
            .overlay(alignment: .bottom) {
                if isActive {
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(Color.white.opacity(0.4))
                        .frame(height: 1)
                        .padding(.horizontal, 8)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .opacity(session.isAlive ? 1 : 0.5)
    }
}
