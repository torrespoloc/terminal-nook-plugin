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

    // Tabs hug content; height stays uniform on the 8pt grid (24pt + 1pt overshoot for visual balance with the 7pt dot).
    private let tabHeight: CGFloat = 24
    private let maxTitleChars = 22

    private var truncatedTitle: String {
        let title = session.title
        return title.count > maxTitleChars
            ? String(title.prefix(maxTitleChars - 1)) + "…"
            : title
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
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

                Text(truncatedTitle)
                    .font(.system(size: 12, weight: isActive ? .semibold : .medium))
                    .foregroundStyle(fgColor)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                // Always in layout — opacity toggle avoids layout reflow
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(NookType.closeGlyph)
                        .foregroundStyle(closeFg)
                        .frame(width: 14, height: 14)
                        .background(closeHoverBg, in: Circle())
                }
                .buttonStyle(.plain)
                .opacity(isHovered || isActive ? 1 : 0)
                .allowsHitTesting(isHovered || isActive)
            }
            .padding(.horizontal, 8)
            .frame(minHeight: tabHeight)
            .background(
                RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                    .fill(tabBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                            .strokeBorder(isActive ? tabBorder : .clear, lineWidth: 0.5)
                    )
                    .shadow(
                        color: isActive ? .black.opacity(0.35) : .clear,
                        radius: isActive ? 2 : 0,
                        y: isActive ? 1 : 0
                    )
                    .overlay(alignment: .top) {
                        if isActive {
                            RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
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


// MARK: - Notes Tab Button (top-bar layout)

struct NotesTabButton: View {
    let isDark: Bool
    let onClose: () -> Void

    @State private var isHovered = false
    private var t: NookTheme { NookTheme(isDark: isDark) }

    private let tabHeight: CGFloat = 24

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "note.text")
                .font(NookType.micro)
                .foregroundStyle(t.fg)
                .frame(width: 10, height: 10)

            Text("My Notes")
                .font(NookType.labelEmph)
                .foregroundStyle(t.fg)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(NookType.closeGlyph)
                    .foregroundStyle(t.fgMid)
                    .frame(width: 14, height: 14)
                    .background(t.stroke2, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .frame(minHeight: tabHeight)
        .background(
            RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                .fill(t.L3)
                .overlay(
                    RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                        .strokeBorder(t.stroke3, lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}

// MARK: - Help Tab Button (top-bar layout)

struct HelpTabButton: View {
    let isDark: Bool
    let onClose: () -> Void

    @State private var isHovered = false
    private var t: NookTheme { NookTheme(isDark: isDark) }

    private let tabHeight: CGFloat = 24

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(NookType.micro)
                .foregroundStyle(t.fg)
                .frame(width: 10, height: 10)

            Text("CL Help")
                .font(NookType.labelEmph)
                .foregroundStyle(t.fg)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(NookType.closeGlyph)
                    .foregroundStyle(t.fgMid)
                    .frame(width: 14, height: 14)
                    .background(t.stroke2, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .frame(minHeight: tabHeight)
        .background(
            RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                .fill(t.L3)
                .overlay(
                    RoundedRectangle(cornerRadius: NookRadius.md, style: .continuous)
                        .strokeBorder(t.stroke3, lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
        )
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
    }
}
