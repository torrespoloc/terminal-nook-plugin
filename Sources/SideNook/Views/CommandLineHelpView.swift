// Sources/SideNook/Views/CommandLineHelpView.swift
import SwiftUI
import AppKit

// MARK: - Data

struct CmdEntry: Identifiable {
    let id = UUID()
    let cmd: String
    let args: String
    let desc: String
}

private func loadCommands() -> [CmdEntry] {
    guard let url = Bundle.main.url(forResource: "command-lines", withExtension: "md", subdirectory: "Metadata") else {
        return []
    }

    guard let content = try? String(contentsOf: url, encoding: .utf8) else {
        return []
    }

    var entries: [CmdEntry] = []
    let lines = content.components(separatedBy: .newlines)

    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        guard trimmed.hasPrefix("|") && !trimmed.contains("---") && !trimmed.contains("Command") else {
            continue
        }

        let parts = trimmed.components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard parts.count >= 3 else { continue }

        let cmd = parts[0]
        let args = parts[1]
        let desc = parts[2]

        entries.append(CmdEntry(cmd: cmd, args: args, desc: desc))
    }

    return entries
}

private let allCmds: [CmdEntry] = loadCommands()

// MARK: - Main View

struct CommandLineHelpView: View {
    @Bindable var state: NookState

    var showsTrigger: Bool = true

    @State private var query: String = ""
    @State private var helpPanelHeight: CGFloat = 248
    @State private var hoveredEntryID: UUID? = nil

    private var t: NookTheme { state.theme }
    private var accentGreen: Color { t.accentReadable }

    private var filteredCmds: [CmdEntry] {
        if query.isEmpty { return allCmds }
        let q = query.lowercased()
        return allCmds.filter {
            $0.cmd.lowercased().contains(q) || $0.desc.lowercased().contains(q)
        }
    }

    var body: some View {
        Group {
            if showsTrigger {
                VStack(spacing: 0) {
                    triggerRow
                    Rectangle().fill(t.stroke1).frame(height: 0.5)
                    if state.showCommandHelp {
                        floatingPanel
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(10)
                    }
                }
            } else {
                floatingPanel
            }
        }
        .environment(\.colorScheme, state.isDark ? .dark : .light)
    }

    // MARK: - Trigger Row

    private var triggerRow: some View {
        Button(action: {
            withAnimation(.easeOut(duration: 0.18)) {
                state.showCommandHelp.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(NookType.label)
                    .foregroundStyle(t.fgMid)

                Text("Command Line Help")
                    .font(NookType.body)
                    .foregroundStyle(t.fgMid)
                    .fixedSize(horizontal: true, vertical: false)

                Spacer(minLength: 0)

                Image(systemName: "chevron.down")
                    .font(NookType.chevron)
                    .foregroundStyle(t.fgMute)
                    .rotationEffect(.degrees(state.showCommandHelp ? 180 : 0))
                    .animation(.easeOut(duration: 0.15), value: state.showCommandHelp)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Resize Handle

    private var resizeHandle: some View {
        HelpResizeHandle(panelHeight: $helpPanelHeight)
            .frame(maxWidth: .infinity, minHeight: 16, maxHeight: 16)
            .overlay {
                Capsule()
                    .fill(t.fgMute.opacity(0.45))
                    .frame(width: 20, height: 4)
                    .allowsHitTesting(false)
            }
    }

    // MARK: - Floating Panel

    private var floatingPanel: some View {
        VStack(spacing: 0) {
            searchBar
            Rectangle().fill(t.stroke1).frame(height: 0.5)
            commandList
            Rectangle().fill(t.stroke1).frame(height: 0.5)
            actionBar
            resizeHandle
        }
        .frame(width: 180)
        .background(t.L1)
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 8,
                bottomTrailingRadius: 8,
                topTrailingRadius: 0,
                style: .continuous
            )
            .strokeBorder(t.stroke2, lineWidth: 0.5)
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 8,
                bottomTrailingRadius: 8,
                topTrailingRadius: 0,
                style: .continuous
            )
        )
        // Shadow only in dark mode — skipped in light mode to avoid visual noise
        .shadow(color: state.isDark ? .black.opacity(0.40) : .clear, radius: 8, x: 0, y: 4)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(NookType.labelReg)
                .foregroundStyle(t.fgMute)
            TextField("Search commands…", text: $query)
                .font(NookType.bodyReg)
                .foregroundStyle(t.fg)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(t.groupBg)
    }

    // MARK: - Command List

    private var commandList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(filteredCmds) { entry in
                    cmdRow(entry)
                    Rectangle().fill(t.stroke1).frame(height: 0.5)
                }
            }
        }
        .frame(height: helpPanelHeight)
    }

    private func cmdRow(_ entry: CmdEntry) -> some View {
        let isHovered = hoveredEntryID == entry.id
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Text(entry.cmd)
                    .font(NookType.bodyMono)
                    .foregroundStyle(accentGreen)
                if !entry.args.isEmpty {
                    Text(" " + entry.args)
                        .font(NookType.bodyMono)
                        .foregroundStyle(accentGreen.opacity(0.70))
                }
            }
            Text(entry.desc)
                .font(NookType.labelReg)
                .foregroundStyle(t.fgMute)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHovered ? t.L3 : Color.clear)
        .contentShape(Rectangle())
        .onHover { over in hoveredEntryID = over ? entry.id : nil }
        .onTapGesture {
            let text = entry.cmd + (entry.args.isEmpty ? "" : " " + entry.args)
            state.activeSession?.send(text: text)
            withAnimation(.easeOut(duration: 0.18)) { state.showCommandHelp = false }
        }
        .animation(.easeOut(duration: 0.10), value: isHovered)
    }

    // MARK: - Action Bar (Open as Tab)

    private var actionBar: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            openAsTabButton
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(t.L1)
    }

    private var openAsTabButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.18)) {
                state.showCommandHelp = false
            }
            state.openHelpTab()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "rectangle.stack.badge.plus")
                    .font(NookType.micro)
                Text("Open as Tab")
                    .font(NookType.caption)
            }
            .foregroundStyle(t.accentReadable)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: NookRadius.xs, style: .continuous)
                    .fill(t.accentTint)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Full-tab help view

/// Shown in the panel content area when `state.helpTabActive` is true.
/// Replaces the terminal with the full command reference list.
struct HelpTabFullView: View {
    @Bindable var state: NookState

    @State private var query: String = ""
    @State private var hoveredEntryID: UUID? = nil

    private var t: NookTheme { state.theme }
    private var accentGreen: Color { t.accentReadable }

    private var filteredCmds: [CmdEntry] {
        if query.isEmpty { return allCmds }
        let q = query.lowercased()
        return allCmds.filter {
            $0.cmd.lowercased().contains(q) || $0.desc.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(t.stroke1).frame(height: 0.5)
            searchBar
            Rectangle().fill(t.stroke1).frame(height: 0.5)
            commandList
        }
        .background(t.L1)
        .clipShape(RoundedRectangle(cornerRadius: NookRadius.lg, style: .continuous))
        .environment(\.colorScheme, state.isDark ? .dark : .light)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(NookType.label)
                .foregroundStyle(t.fgMid)
            Text("Command Line Help")
                .font(NookType.body)
                .foregroundStyle(t.fgMid)
            Spacer(minLength: 0)
            Text("\(filteredCmds.count)")
                .font(NookType.microMono)
                .foregroundStyle(t.fgMute)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(t.L1)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(NookType.labelReg)
                .foregroundStyle(t.fgMute)
            TextField("Search commands…", text: $query)
                .font(NookType.bodyReg)
                .foregroundStyle(t.fg)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(t.groupBg)
    }

    private var commandList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 0) {
                ForEach(filteredCmds) { entry in
                    cmdRow(entry)
                    Rectangle().fill(t.stroke1).frame(height: 0.5)
                }
            }
        }
    }

    private func cmdRow(_ entry: CmdEntry) -> some View {
        let isHovered = hoveredEntryID == entry.id
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 0) {
                Text(entry.cmd)
                    .font(NookType.bodyMono)
                    .foregroundStyle(accentGreen)
                if !entry.args.isEmpty {
                    Text(" " + entry.args)
                        .font(NookType.bodyMono)
                        .foregroundStyle(accentGreen.opacity(0.70))
                }
            }
            Text(entry.desc)
                .font(NookType.labelReg)
                .foregroundStyle(t.fgMute)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHovered ? t.L3 : Color.clear)
        .contentShape(Rectangle())
        .onHover { over in hoveredEntryID = over ? entry.id : nil }
        .onTapGesture {
            let text = entry.cmd + (entry.args.isEmpty ? "" : " " + entry.args)
            state.activeSession?.send(text: text)
        }
        .animation(.easeOut(duration: 0.10), value: isHovered)
    }
}

// MARK: - Help Panel Resize Handle (AppKit-backed)

private struct HelpResizeHandle: NSViewRepresentable {
    @Binding var panelHeight: CGFloat

    func makeNSView(context: Context) -> HelpResizeNSView {
        let v = HelpResizeNSView()
        v.onHeightChange = { context.coordinator.update(height: $0) }
        return v
    }

    func updateNSView(_ nsView: HelpResizeNSView, context: Context) {
        nsView.currentHeight = panelHeight
    }

    func makeCoordinator() -> Coordinator { Coordinator(panelHeight: $panelHeight) }

    final class Coordinator {
        var panelHeight: Binding<CGFloat>
        init(panelHeight: Binding<CGFloat>) { self.panelHeight = panelHeight }
        func update(height: CGFloat) { panelHeight.wrappedValue = height }
    }
}

private final class HelpResizeNSView: NSView {
    var onHeightChange: ((CGFloat) -> Void)?
    var currentHeight: CGFloat = 248
    private var dragStartY: CGFloat = 0
    private var dragStartHeight: CGFloat = 0

    override var mouseDownCanMoveWindow: Bool { false }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .resizeUpDown)
    }

    override func mouseDown(with event: NSEvent) {
        dragStartY = NSEvent.mouseLocation.y
        dragStartHeight = currentHeight
    }

    override func mouseDragged(with event: NSEvent) {
        let dy = NSEvent.mouseLocation.y - dragStartY
        let newHeight = max(80, min(384, dragStartHeight - dy))
        onHeightChange?(newHeight)
    }

    override func mouseUp(with event: NSEvent) {}
}
