// Sources/SideNook/Views/CommandLineHelpView.swift
import SwiftUI

// MARK: - Data

struct CmdEntry {
    let cmd: String
    let args: String
    let desc: String
}

private let allCmds: [CmdEntry] = [
    CmdEntry(cmd: "ls",     args: "[-la]",              desc: "List directory contents. -l = long format, -a = show hidden."),
    CmdEntry(cmd: "pwd",    args: "",                   desc: "Print the current working directory path."),
    CmdEntry(cmd: "cd",     args: "<dir>",              desc: "Change directory. Use ~ for home, .. for parent."),
    CmdEntry(cmd: "cat",    args: "<file>",             desc: "Print file contents to stdout."),
    CmdEntry(cmd: "echo",   args: "<text>",             desc: "Print text to stdout."),
    CmdEntry(cmd: "clear",  args: "",                   desc: "Clear the terminal screen. Shortcut: ⌘L or Ctrl+L."),
    CmdEntry(cmd: "date",   args: "",                   desc: "Print the current date and time."),
    CmdEntry(cmd: "whoami", args: "",                   desc: "Print the current logged-in username."),
    CmdEntry(cmd: "grep",   args: "<pattern> <file>",   desc: "Search for a pattern in files. -r for recursive."),
    CmdEntry(cmd: "find",   args: "<dir> -name",        desc: "Find files by name or type."),
    CmdEntry(cmd: "mkdir",  args: "<dir>",              desc: "Create a new directory."),
    CmdEntry(cmd: "rm",     args: "[-rf] <file>",       desc: "Remove files or directories. -r = recursive, -f = force."),
    CmdEntry(cmd: "cp",     args: "<src> <dest>",       desc: "Copy files or directories."),
    CmdEntry(cmd: "mv",     args: "<src> <dest>",       desc: "Move or rename files."),
    CmdEntry(cmd: "chmod",  args: "<mode> <file>",      desc: "Change file permissions (e.g. 755, +x)."),
    CmdEntry(cmd: "git",    args: "<subcommand>",       desc: "Version control. Common: status, add, commit, push, pull."),
    CmdEntry(cmd: "swift",  args: "build|test|run",     desc: "Build, test, or run a Swift package."),
    CmdEntry(cmd: "claude", args: "",                   desc: "Launch Claude Code in this terminal session."),
    CmdEntry(cmd: "exit",   args: "",                   desc: "Close the current terminal tab."),
]

private func getReply(_ input: String) -> String {
    let q = input.lowercased()
    if q.contains("large file") || q.contains("disk space") || q.contains("size") {
        return "Find large files:\n\n  find . -size +100M\n\nSorted by size:\n\n  du -sh * | sort -rh | head -20"
    }
    if q.contains("hidden") || q.contains("dotfile") {
        return "Hidden files start with a dot. List them:\n\n  ls -la\n\nThe -a flag shows all files including hidden ones."
    }
    if q.contains("permiss") || q.contains("chmod") {
        return "Change permissions with chmod:\n\n  chmod 755 file   # rwxr-xr-x\n  chmod +x script  # make executable"
    }
    if q.contains("git") {
        return "Common git workflow:\n\n  git status\n  git add .\n  git commit -m \"msg\"\n  git push origin main"
    }
    if q.contains("swift") || q.contains("build") {
        return "Swift package commands:\n\n  swift build   # compile\n  swift test    # run tests\n  swift run     # build + run"
    }
    if let match = allCmds.first(where: { q.contains($0.cmd) }) {
        return match.cmd + (match.args.isEmpty ? "" : " " + match.args) + "\n\n" + match.desc
    }
    return "I can help with shell commands. Try asking about ls, git, find — or describe what you want to do."
}

// MARK: - Chat Message

private struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
}

// MARK: - Main View

struct CommandLineHelpView: View {
    @Bindable var state: NookState

    // Chat local state
    @State private var chatLines: [ChatMessage] = [
        ChatMessage(isUser: false, text: "Ask me anything about shell commands.")
    ]
    @State private var chatInput: String = ""
    @State private var query: String = ""

    private var t: NookTheme { state.theme }
    private let accentGreen = Color(red: 0.21, green: 0.82, blue: 0.50)
    private let panelHeight: CGFloat = 340

    private var filteredCmds: [CmdEntry] {
        if query.isEmpty { return allCmds }
        let q = query.lowercased()
        return allCmds.filter {
            $0.cmd.contains(q) || $0.desc.lowercased().contains(q)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Trigger row area (always visible)
            VStack(spacing: 0) {
                Rectangle().fill(t.stroke1).frame(height: 0.5)
                triggerRow
            }
            // Floating panel anchored just above trigger row
            .overlay(alignment: .top) {
                if state.showCommandHelp {
                    floatingPanel
                        .offset(y: -panelHeight)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }
            }
        }
    }

    // MARK: - Trigger Row

    private var triggerRow: some View {
        Button(action: {
            withAnimation(.easeOut(duration: 0.18)) {
                state.showCommandHelp.toggle()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(t.fgMid)

                Text("Command Line Help")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(t.fgMid)

                Spacer(minLength: 0)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(t.fgMute)
                    .rotationEffect(.degrees(state.showCommandHelp ? 180 : 0))
                    .animation(.easeOut(duration: 0.15), value: state.showCommandHelp)
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Floating Panel

    private var floatingPanel: some View {
        VStack(spacing: 0) {
            // Mode toggle header
            HStack(spacing: 0) {
                modeTab(label: "Reference", mode: .list)
                modeTab(label: "Chat", mode: .chat)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 6)

            Rectangle().fill(t.stroke1).frame(height: 0.5)

            // Panel content
            if state.commandHelpMode == .list {
                listModeContent
            } else {
                chatModeContent
            }
        }
        .frame(width: 180, height: panelHeight)
        .background(t.L1)
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 8,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 8,
                style: .continuous
            )
            .strokeBorder(t.stroke2, lineWidth: 0.5)
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 8,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 8,
                style: .continuous
            )
        )
        .shadow(color: .black.opacity(0.40), radius: 8, x: 0, y: -4)
    }

    private func modeTab(label: String, mode: NookState.CommandHelpMode) -> some View {
        let isSelected = state.commandHelpMode == mode
        return Button(action: { state.commandHelpMode = mode }) {
            Text(label)
                .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? t.fg : t.fgMute)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(isSelected ? t.L3 : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - List Mode

    private var listModeContent: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundStyle(t.fgMute)
                TextField("Search commands…", text: $query)
                    .font(.system(size: 11))
                    .foregroundStyle(t.fg)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Rectangle().fill(t.stroke1).frame(height: 0.5)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(filteredCmds, id: \.cmd) { entry in
                        cmdRow(entry)
                        Rectangle().fill(t.stroke1).frame(height: 0.5)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
    }

    private func cmdRow(_ entry: CmdEntry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 0) {
                Text(entry.cmd)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(accentGreen)
                if !entry.args.isEmpty {
                    Text(" " + entry.args)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(accentGreen.opacity(0.70))
                }
            }
            Text(entry.desc)
                .font(.system(size: 11))
                .foregroundStyle(t.fgMute)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Chat Mode

    private var chatModeContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Command Line Help")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(t.fg)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            Rectangle().fill(t.stroke1).frame(height: 0.5)

            // Quick-pick search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundStyle(t.fgMute)
                TextField("Search suggestions…", text: $query)
                    .font(.system(size: 11))
                    .foregroundStyle(t.fg)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)

            Rectangle().fill(t.stroke1).frame(height: 0.5)

            // Quick-pick suggestions (when query non-empty)
            if !query.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredCmds.prefix(4), id: \.cmd) { entry in
                            Button(action: {
                                chatInput = entry.cmd + (entry.args.isEmpty ? "" : " " + entry.args)
                                query = ""
                            }) {
                                HStack(spacing: 4) {
                                    Text(entry.cmd)
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(accentGreen)
                                    if !entry.args.isEmpty {
                                        Text(entry.args)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundStyle(accentGreen.opacity(0.65))
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(t.L3.opacity(0.6))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            Rectangle().fill(t.stroke1).frame(height: 0.5)
                        }
                    }
                }
                .frame(maxHeight: 90)

                Rectangle().fill(t.stroke1).frame(height: 0.5)
            }

            // Chat messages
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(chatLines) { msg in
                            chatBubble(msg)
                                .id(msg.id)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
                .onChange(of: chatLines.count) { _, _ in
                    if let last = chatLines.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Rectangle().fill(t.stroke1).frame(height: 0.5)

            // Input row
            HStack(spacing: 6) {
                TextField("Ask a question…", text: $chatInput)
                    .font(.system(size: 11))
                    .foregroundStyle(t.fg)
                    .textFieldStyle(.plain)
                    .onSubmit { sendChat() }

                Button(action: sendChat) {
                    Text("↑")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.80))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(accentGreen))
                }
                .buttonStyle(.plain)
                .disabled(chatInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
        }
    }

    private func chatBubble(_ msg: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 0) {
            if msg.isUser { Spacer(minLength: 16) }
            Text(msg.text)
                .font(.system(size: 11))
                .foregroundStyle(msg.isUser ? Color.black.opacity(0.85) : t.fg)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(msg.isUser ? accentGreen.opacity(0.85) : t.L3)
                )
                .frame(maxWidth: .infinity, alignment: msg.isUser ? .trailing : .leading)
            if !msg.isUser { Spacer(minLength: 16) }
        }
    }

    private func sendChat() {
        let text = chatInput.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        chatInput = ""
        query = ""
        chatLines.append(ChatMessage(isUser: true, text: text))
        let reply = getReply(text)
        chatLines.append(ChatMessage(isUser: false, text: reply))
    }
}
