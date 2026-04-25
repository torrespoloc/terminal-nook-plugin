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

// MARK: - Main View

struct CommandLineHelpView: View {
    @Bindable var state: NookState

    @State private var query: String = ""

    private var t: NookTheme { state.theme }
    private let accentGreen = Color(red: 0.21, green: 0.82, blue: 0.50)

    private var filteredCmds: [CmdEntry] {
        if query.isEmpty { return allCmds }
        let q = query.lowercased()
        return allCmds.filter {
            $0.cmd.contains(q) || $0.desc.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if state.showCommandHelp {
                floatingPanel
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }
            Rectangle().fill(t.stroke1).frame(height: 0.5)
            triggerRow
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
            HStack(spacing: 8) {                                    // 6 → 8
                Image(systemName: "info.circle")
                    .font(.system(size: 12, weight: .medium))       // 12 ✓ (on 4-grid)
                    .foregroundStyle(t.fgMid)

                Text("Command Line Help")
                    .font(.system(size: 14, weight: .medium))       // 13 → 14 (2px scale)
                    .foregroundStyle(t.fgMid)

                Spacer(minLength: 0)

                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .medium))        // 10 → 8 (on 4-grid)
                    .foregroundStyle(t.fgMute)
                    .rotationEffect(.degrees(state.showCommandHelp ? 180 : 0))
                    .animation(.easeOut(duration: 0.15), value: state.showCommandHelp)
            }
            .padding(.vertical, 8)                                  // 8 ✓
            .padding(.horizontal, 12)                               // 12 ✓
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Floating Panel

    private var floatingPanel: some View {
        VStack(spacing: 0) {
            searchBar
            Rectangle().fill(t.stroke1).frame(height: 0.5)
            commandList
        }
        .frame(width: 180)
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

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {                                        // 6 → 8
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))                           // 11 → 12 (on 4-grid)
                .foregroundStyle(t.fgMute)
            TextField("Search commands…", text: $query)
                .font(.system(size: 14))                           // 13 → 14 (2px scale)
                .foregroundStyle(t.fg)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)                                  // 10 → 12
        .padding(.vertical, 8)                                     // 8 ✓
        .background(state.isDark ? Color.black.opacity(0.30) : Color.black.opacity(0.05))
    }

    // MARK: - Command List

    private var commandList: some View {
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

    private func cmdRow(_ entry: CmdEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {                  // 3 → 4
            HStack(spacing: 0) {
                Text(entry.cmd)
                    .font(.system(size: 14, design: .monospaced))  // 13 → 14
                    .foregroundStyle(accentGreen)
                if !entry.args.isEmpty {
                    Text(" " + entry.args)
                        .font(.system(size: 14, design: .monospaced)) // 13 → 14
                        .foregroundStyle(accentGreen.opacity(0.70))
                }
            }
            Text(entry.desc)
                .font(.system(size: 12))                           // 12 ✓ (secondary text, min)
                .foregroundStyle(t.fgMute)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)                                  // 10 → 12
        .padding(.vertical, 8)                                     // 7 → 8
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
