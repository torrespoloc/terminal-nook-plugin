// Sources/SideNook/Views/CommandLineHelpView.swift
import SwiftUI

// MARK: - Data

struct CmdEntry: Identifiable {
    let id = UUID()
    let cmd: String
    let args: String
    let desc: String
}

private let allCmds: [CmdEntry] = [
    // ── Core Unix ──────────────────────────────────────────────────────
    CmdEntry(cmd: "ls",       args: "[-la]",               desc: "List directory contents. -l = long format, -a = show hidden."),
    CmdEntry(cmd: "pwd",      args: "",                    desc: "Print the current working directory path."),
    CmdEntry(cmd: "cd",       args: "<dir>",               desc: "Change directory. Use ~ for home, .. for parent."),
    CmdEntry(cmd: "cat",      args: "<file>",              desc: "Print file contents to stdout."),
    CmdEntry(cmd: "echo",     args: "<text>",              desc: "Print text to stdout."),
    CmdEntry(cmd: "clear",    args: "",                    desc: "Clear the terminal screen. Shortcut: ⌘K or ⌘L."),
    CmdEntry(cmd: "date",     args: "",                    desc: "Print the current date and time."),
    CmdEntry(cmd: "whoami",   args: "",                    desc: "Print the current logged-in username."),
    CmdEntry(cmd: "grep",     args: "<pattern> <file>",    desc: "Search for a pattern in files. -r for recursive search."),
    CmdEntry(cmd: "find",     args: "<dir> -name",         desc: "Find files by name or type."),
    CmdEntry(cmd: "mkdir",    args: "<dir>",               desc: "Create a new directory."),
    CmdEntry(cmd: "rm",       args: "[-rf] <file>",        desc: "Remove files or directories. -r = recursive, -f = force."),
    CmdEntry(cmd: "cp",       args: "<src> <dest>",        desc: "Copy files or directories."),
    CmdEntry(cmd: "mv",       args: "<src> <dest>",        desc: "Move or rename files."),
    CmdEntry(cmd: "chmod",    args: "<mode> <file>",       desc: "Change file permissions (e.g. 755, +x)."),
    CmdEntry(cmd: "touch",    args: "<file>",              desc: "Create an empty file or update a file's modification time."),
    CmdEntry(cmd: "ln",       args: "-s <src> <link>",     desc: "Create a symbolic link. Useful for dotfile management."),
    CmdEntry(cmd: "head",     args: "-n 20 <file>",        desc: "Print the first N lines of a file (default 10)."),
    CmdEntry(cmd: "tail",     args: "-f <file>",           desc: "Stream new lines as they are written. Great for log files."),
    CmdEntry(cmd: "less",     args: "<file>",              desc: "Page through a file. Press q to quit, / to search."),
    CmdEntry(cmd: "diff",     args: "<file1> <file2>",     desc: "Compare two files line by line."),
    CmdEntry(cmd: "wc",       args: "-l",                  desc: "Count lines (-l), words (-w), or characters (-c)."),
    CmdEntry(cmd: "sort",     args: "[-rn]",               desc: "Sort lines. -r = reverse, -n = numeric, -k2 = by column 2."),
    CmdEntry(cmd: "uniq",     args: "",                    desc: "Remove duplicate adjacent lines. Usually paired with sort."),
    CmdEntry(cmd: "sed",      args: "'s/old/new/g' <file>", desc: "Stream edit: find-and-replace text in a file."),
    CmdEntry(cmd: "awk",      args: "'{print $1}' <file>", desc: "Process text by columns. Useful for log and CSV parsing."),
    CmdEntry(cmd: "xargs",    args: "",                    desc: "Build and run commands from stdin. E.g.: ls | xargs rm"),
    CmdEntry(cmd: "tar",      args: "-czf out.tar.gz .",   desc: "Compress a directory. Use -xzf to decompress a .tar.gz."),
    CmdEntry(cmd: "unzip",    args: "<file>",              desc: "Extract a .zip archive in the current directory."),
    CmdEntry(cmd: "df",       args: "-h",                  desc: "Show disk space usage in human-readable form."),
    CmdEntry(cmd: "du",       args: "-sh *",               desc: "Show size of each item in the current directory."),

    // ── Process & System ──────────────────────────────────────────────
    CmdEntry(cmd: "top",      args: "",                    desc: "Live CPU and memory usage per process. Press q to quit."),
    CmdEntry(cmd: "ps",       args: "aux",                 desc: "List all running processes with user and CPU usage."),
    CmdEntry(cmd: "kill",     args: "-9 <pid>",            desc: "Force-terminate a process by its PID."),
    CmdEntry(cmd: "killall",  args: "<app>",               desc: "Force-quit a macOS app by name. E.g.: killall Finder"),
    CmdEntry(cmd: "open",     args: "<path>",              desc: "Open a file or URL in its default macOS app."),

    // ── Shell Environment ─────────────────────────────────────────────
    CmdEntry(cmd: "env",      args: "",                    desc: "Print all current environment variables."),
    CmdEntry(cmd: "export",   args: "VAR=value",           desc: "Set an environment variable for the current shell session."),
    CmdEntry(cmd: "source",   args: "~/.zshrc",            desc: "Reload your shell config without opening a new terminal."),
    CmdEntry(cmd: "alias",    args: "",                    desc: "List all active shell aliases."),
    CmdEntry(cmd: "which",    args: "<cmd>",               desc: "Show the filesystem path to an executable."),
    CmdEntry(cmd: "man",      args: "<cmd>",               desc: "Open the manual page for any command. Press q to quit."),
    CmdEntry(cmd: "history",  args: "",                    desc: "Print your command history. Pipe to grep to search it."),

    // ── macOS Clipboard ───────────────────────────────────────────────
    CmdEntry(cmd: "pbcopy",   args: "",                    desc: "Pipe stdin to the clipboard. E.g.: cat file.txt | pbcopy"),
    CmdEntry(cmd: "pbpaste",  args: "",                    desc: "Paste clipboard contents to stdout."),

    // ── Network ───────────────────────────────────────────────────────
    CmdEntry(cmd: "curl",     args: "-s <url>",            desc: "Fetch a URL and print the response. Pipe to jq for JSON."),
    CmdEntry(cmd: "ssh",      args: "user@host",           desc: "Securely connect to a remote server over SSH."),
    CmdEntry(cmd: "scp",      args: "<src> user@host:<dest>", desc: "Securely copy files to or from a remote server."),
    CmdEntry(cmd: "ping",     args: "<host>",              desc: "Test network connectivity. Press ⌃C to stop."),

    // ── JSON ──────────────────────────────────────────────────────────
    CmdEntry(cmd: "jq",       args: "'.<key>' file.json",  desc: "Parse and filter JSON from the command line."),

    // ── File Search ───────────────────────────────────────────────────
    CmdEntry(cmd: "fd",       args: "<pattern>",           desc: "Fast, friendly file finder. Faster alternative to find."),
    CmdEntry(cmd: "rg",       args: "<pattern>",           desc: "Search file contents with ripgrep. --type ts to filter."),

    // ── Git ───────────────────────────────────────────────────────────
    CmdEntry(cmd: "git",      args: "status|add|commit|push|pull", desc: "Core version control workflow."),
    CmdEntry(cmd: "git stash", args: "push -m <name>",     desc: "Save uncommitted changes with a name for later."),
    CmdEntry(cmd: "git log",   args: "--oneline --graph",  desc: "Visual branch history in the terminal."),
    CmdEntry(cmd: "git restore", args: "<file>",           desc: "Discard unstaged changes to a specific file."),
    CmdEntry(cmd: "git switch", args: "-c <branch>",       desc: "Create and switch to a new branch (modern syntax)."),
    CmdEntry(cmd: "git add",   args: "-p",                 desc: "Interactively stage hunks, not whole files."),
    CmdEntry(cmd: "git rebase", args: "-i HEAD~<n>",       desc: "Interactive rebase — squash or rename last N commits."),
    CmdEntry(cmd: "git diff",  args: "HEAD~1 -- <path>",   desc: "Compare a specific path against the previous commit."),
    CmdEntry(cmd: "git tag",   args: "v1.0.0",             desc: "Tag a release. Push tags with: git push --tags"),

    // ── GitHub CLI ────────────────────────────────────────────────────
    CmdEntry(cmd: "gh pr",     args: "create --fill",      desc: "Create a pull request using the commit message as title."),
    CmdEntry(cmd: "gh pr",     args: "list",               desc: "List all open pull requests in the repo."),
    CmdEntry(cmd: "gh pr",     args: "merge --squash",     desc: "Squash-merge a pull request from the terminal."),
    CmdEntry(cmd: "gh pr",     args: "view --web",         desc: "Open the current branch's pull request in the browser."),
    CmdEntry(cmd: "gh issue",  args: "create",             desc: "File a bug or feature issue without leaving the terminal."),
    CmdEntry(cmd: "gh run",    args: "list",               desc: "See CI/CD workflow runs for the current repo."),

    // ── Docker ───────────────────────────────────────────────────────
    CmdEntry(cmd: "docker ps", args: "",                   desc: "List currently running containers."),
    CmdEntry(cmd: "docker compose", args: "up",            desc: "Start all services defined in compose.yml."),
    CmdEntry(cmd: "docker compose", args: "down",          desc: "Stop and remove all running containers."),
    CmdEntry(cmd: "docker exec", args: "-it <id> zsh",     desc: "Open a shell inside a running container for debugging."),
    CmdEntry(cmd: "docker system", args: "prune",          desc: "Free disk space by clearing unused images and containers."),

    // ── Homebrew ─────────────────────────────────────────────────────
    CmdEntry(cmd: "brew install", args: "<tool>",          desc: "Install a CLI tool via Homebrew."),
    CmdEntry(cmd: "brew upgrade", args: "",                desc: "Update all Homebrew-installed packages to latest versions."),
    CmdEntry(cmd: "brew list",  args: "",                  desc: "Show all packages installed via Homebrew."),
    CmdEntry(cmd: "brew doctor", args: "",                 desc: "Diagnose common Homebrew issues."),
    CmdEntry(cmd: "brew services", args: "list",           desc: "See background services managed by Homebrew."),

    // ── pnpm / npm ───────────────────────────────────────────────────
    CmdEntry(cmd: "pnpm install", args: "",                desc: "Install project dependencies (faster, disk-efficient)."),
    CmdEntry(cmd: "pnpm add",   args: "<pkg>",             desc: "Add a dependency. Use -D for dev dependencies."),
    CmdEntry(cmd: "pnpm run",   args: "<script>",          desc: "Run a package.json script."),
    CmdEntry(cmd: "pnpm storybook", args: "",              desc: "Start Storybook dev server on port 6006."),
    CmdEntry(cmd: "npm install", args: "",                 desc: "Install dependencies from package.json (npm fallback)."),

    // ── Node / Runtime ───────────────────────────────────────────────
    CmdEntry(cmd: "node",       args: "--version",         desc: "Verify your Node.js version (should be 20+ LTS)."),
    CmdEntry(cmd: "nvm use",    args: "--lts",             desc: "Switch to the latest Node.js LTS version."),

    // ── Python ───────────────────────────────────────────────────────
    CmdEntry(cmd: "pip install", args: "<pkg>",            desc: "Install a Python package or CLI tool."),
    CmdEntry(cmd: "python3",    args: "-m http.server 8080", desc: "Instant local server for any static folder. Zero config."),

    // ── Make ─────────────────────────────────────────────────────────
    CmdEntry(cmd: "make run",   args: "",                  desc: "Start the dev environment (if Makefile defines run)."),
    CmdEntry(cmd: "make build", args: "",                  desc: "Run the production build via Makefile."),
    CmdEntry(cmd: "make test",  args: "",                  desc: "Run the test suite via Makefile."),
    CmdEntry(cmd: "make clean", args: "",                  desc: "Remove build artefacts defined in the Makefile."),

    // ── Swift ────────────────────────────────────────────────────────
    CmdEntry(cmd: "swift",      args: "build|test|run",    desc: "Build, test, or run a Swift package."),

    // ── AI Tools ─────────────────────────────────────────────────────
    CmdEntry(cmd: "claude",     args: "",                  desc: "Launch Claude Code in this terminal session."),

    // ── Session ──────────────────────────────────────────────────────
    CmdEntry(cmd: "exit",       args: "",                  desc: "Close the current terminal tab."),
]

// MARK: - Main View

struct CommandLineHelpView: View {
    @Bindable var state: NookState

    @State private var query: String = ""
    @State private var helpPanelHeight: CGFloat = 248
    @State private var dragStartHeight: CGFloat = 248
    @State private var hoveredEntryID: UUID? = nil

    private var t: NookTheme { state.theme }
    private var accentGreen: Color { t.accent }

    private var filteredCmds: [CmdEntry] {
        if query.isEmpty { return allCmds }
        let q = query.lowercased()
        return allCmds.filter {
            $0.cmd.lowercased().contains(q) || $0.desc.lowercased().contains(q)
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
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(t.fgMid)

                Text("Command Line Help")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(t.fgMid)

                Spacer(minLength: 0)

                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(t.fgMute)
                    .rotationEffect(.degrees(state.showCommandHelp ? 180 : 0))
                    .animation(.easeOut(duration: 0.15), value: state.showCommandHelp)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Resize Handle

    private var resizeHandle: some View {
        ZStack {
            Capsule()
                .fill(t.fgMute.opacity(0.45))
                .frame(width: 20, height: 3)
        }
        .frame(maxWidth: .infinity, minHeight: 12, maxHeight: 12)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    helpPanelHeight = max(80, min(380, dragStartHeight - value.translation.height))
                }
                .onEnded { value in
                    helpPanelHeight = max(80, min(380, dragStartHeight - value.translation.height))
                    dragStartHeight = helpPanelHeight
                }
        )
        .onHover { isHovering in
            if isHovering {
                NSCursor.resizeUpDown.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }

    // MARK: - Floating Panel

    private var floatingPanel: some View {
        VStack(spacing: 0) {
            resizeHandle
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
        // Shadow only in dark mode — skipped in light mode to avoid visual noise
        .shadow(color: state.isDark ? .black.opacity(0.40) : .clear, radius: 8, x: 0, y: -4)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(t.fgMute)
            TextField("Search commands…", text: $query)
                .font(.system(size: 13))
                .foregroundStyle(t.fg)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(state.isDark ? Color.black.opacity(0.30) : Color.black.opacity(0.05))
    }

    // MARK: - Command List

    private var commandList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
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
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(accentGreen)
                if !entry.args.isEmpty {
                    Text(" " + entry.args)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(accentGreen.opacity(0.70))
                }
            }
            Text(entry.desc)
                .font(.system(size: 12))
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
}
