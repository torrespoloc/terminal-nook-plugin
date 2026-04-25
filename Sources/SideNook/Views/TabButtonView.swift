// Sources/SideNook/Views/TabButtonView.swift
import SwiftUI

struct TabButtonView: View {
    let session: TerminalSession
    let isActive: Bool
    let isDark: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovered = false
    @State private var attnOpacity: Double = 1.0

    // MARK: - Palette

    private var fgColor: Color {
        if isActive  { return isDark ? Color.white.opacity(0.90) : Color.black.opacity(0.85) }
        if isHovered { return isDark ? Color.white.opacity(0.70) : Color.black.opacity(0.65) }
        return isDark ? Color.white.opacity(0.45) : Color.black.opacity(0.42)
    }

    private var tabBg: Color {
        if isActive  { return isDark ? Color.white.opacity(0.095) : Color.white.opacity(0.95) }
        if isHovered { return isDark ? Color.white.opacity(0.035) : Color.black.opacity(0.025) }
        return Color.clear
    }

    private var tabBorder: Color {
        isDark ? Color.white.opacity(0.13) : Color.black.opacity(0.12)
    }

    private var innerHighlight: Color {
        isDark ? Color.white.opacity(0.06) : Color.white.opacity(0.90)
    }

    private var closeFg: Color {
        isDark ? Color.white.opacity(0.50) : Color.black.opacity(0.45)
    }

    private var closeHoverBg: Color {
        isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
    }

    private var dotColor: Color {
        switch session.status {
        case .live: return Color(red: 0.21, green: 0.82, blue: 0.50)  // #35d07f
        case .attn: return Color(red: 0.95, green: 0.71, blue: 0.18)  // #f0b429
        case .dead: return .red.opacity(0.5)
        }
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 7) {
                // Status dot
                Circle()
                    .fill(dotColor)
                    .frame(width: 7, height: 7)
                    .shadow(color: session.status != .dead ? dotColor.opacity(0.53) : .clear, radius: 3)
                    .opacity(session.status == .attn ? attnOpacity : 1)
                    .onAppear {
                        if session.status == .attn {
                            withAnimation(.easeInOut(duration: 0.55).repeatForever()) {
                                attnOpacity = 0.25
                            }
                        }
                    }
                    .onChange(of: session.status) { _, newStatus in
                        if newStatus == .attn {
                            withAnimation(.easeInOut(duration: 0.55).repeatForever()) {
                                attnOpacity = 0.25
                            }
                        } else {
                            withAnimation { attnOpacity = 1 }
                        }
                    }

                Text(session.title)
                    .font(.system(size: 12, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(fgColor)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if isHovered || isActive {
                    Spacer(minLength: 0)

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(closeFg)
                            .frame(width: 14, height: 14)
                            .background(closeHoverBg, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.animation(.easeOut(duration: 0.1)))
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, isHovered || isActive ? 4 : 10)
            .frame(height: 26)
            .frame(minWidth: 84, maxWidth: 174)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(tabBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(isActive ? tabBorder : .clear, lineWidth: 0.5)
                    )
                    .shadow(
                        color: isActive ? .black.opacity(0.35) : .clear,
                        radius: isActive ? 2 : 0,
                        y: isActive ? 1 : 0
                    )
                    .overlay(alignment: .top) {
                        if isActive {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [innerHighlight, .clear],
                                        startPoint: .top,
                                        endPoint: .center
                                    ),
                                    lineWidth: 0.5
                                )
                                .allowsHitTesting(false)
                        }
                    }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .animation(.easeOut(duration: 0.15), value: isActive)
    }
}
