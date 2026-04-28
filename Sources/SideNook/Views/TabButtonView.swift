// Sources/SideNook/Views/TabButtonView.swift
import SwiftUI

struct TabButtonView: View {
    let session: TerminalSession
    let isActive: Bool
    let isDark: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    let onRename: (String) -> Void

    @State private var isHovered = false
    @State private var attnOpacity: Double = 1.0
    @State private var isRenaming = false
    @State private var renameText = ""

    private var t: NookTheme { NookTheme(isDark: isDark) }

    // MARK: - Palette

    private var fgColor: Color {
        if isActive  { return t.fg }
        if isHovered { return t.fgMid }
        return t.fgMid
    }

    private var tabBg: Color {
        if isActive  { return t.L3 }
        if isHovered { return t.L1 }
        return Color.clear
    }

    private var tabBorder: Color { t.stroke3 }

    private var innerHighlight: Color { t.innerHighlight }

    private var closeFg: Color { t.fgMid }

    private var closeHoverBg: Color { t.stroke2 }

    private var dotColor: Color {
        switch session.status {
        case .idle: return t.dotIdle
        case .live: return t.dotLive
        case .attn: return t.dotAttn
        case .dead: return t.dotDead
        }
    }

    // Tabs flex to fill their container; height stays uniform on the 8pt grid (24pt + 1pt overshoot for visual balance with the 7pt dot).
    private let tabHeight: CGFloat = 24

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 7, height: 7)
                    .shadow(color: session.status == .idle || session.status == .dead ? .clear : dotColor.opacity(0.53), radius: 3)
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
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Always in layout — opacity toggle avoids layout reflow
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(closeFg)
                        .frame(width: 14, height: 14)
                        .background(closeHoverBg, in: Circle())
                }
                .buttonStyle(.plain)
                .opacity(isHovered || isActive ? 1 : 0)
                .allowsHitTesting(isHovered || isActive)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: tabHeight)
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
        .contextMenu {
            Button("Rename Tab") {
                renameText = session.title
                isRenaming = true
            }
            Divider()
            Button("Close Tab", role: .destructive, action: onClose)
        }
        .alert("Rename Tab", isPresented: $isRenaming) {
            TextField("Tab name", text: $renameText)
            Button("Rename") {
                let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { onRename(trimmed) }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onDrag {
            NSItemProvider(object: session.id.uuidString as NSString)
        }
    }
}
