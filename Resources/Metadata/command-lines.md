# Command Line Reference

| Command | Arguments | Description |
|---------|-----------|-------------|
| ls | [-la] | List directory contents. -l = long format, -a = show hidden. |
| pwd | | Print the current working directory path. |
| cd | <dir> | Change directory. Use ~ for home, .. for parent. |
| cat | <file> | Print file contents to stdout. |
| echo | <text> | Print text to stdout. |
| clear | | Clear the terminal screen. Shortcut: ⌘K or ⌘L. |
| date | | Print the current date and time. |
| whoami | | Print the current logged-in username. |
| grep | <pattern> <file> | Search for a pattern in files. -r for recursive search. |
| find | <dir> -name | Find files by name or type. |
| mkdir | <dir> | Create a new directory. |
| rm | [-rf] <file> | Remove files or directories. -r = recursive, -f = force. |
| cp | <src> <dest> | Copy files or directories. |
| mv | <src> <dest> | Move or rename files. |
| chmod | <mode> <file> | Change file permissions (e.g. 755, +x). |
| touch | <file> | Create an empty file or update a file's modification time. |
| ln | -s <src> <link> | Create a symbolic link. Useful for dotfile management. |
| head | -n 20 <file> | Print the first N lines of a file (default 10). |
| tail | -f <file> | Stream new lines as they are written. Great for log files. |
| less | <file> | Page through a file. Press q to quit, / to search. |
| diff | <file1> <file2> | Compare two files line by line. |
| wc | -l | Count lines (-l), words (-w), or characters (-c). |
| sort | [-rn] | Sort lines. -r = reverse, -n = numeric, -k2 = by column 2. |
| uniq | | Remove duplicate adjacent lines. Usually paired with sort. |
| sed | 's/old/new/g' <file> | Stream edit: find-and-replace text in a file. |
| awk | '{print $1}' <file> | Process text by columns. Useful for log and CSV parsing. |
| xargs | | Build and run commands from stdin. E.g.: ls \| xargs rm |
| tar | -czf out.tar.gz . | Compress a directory. Use -xzf to decompress a .tar.gz. |
| unzip | <file> | Extract a .zip archive in the current directory. |
| df | -h | Show disk space usage in human-readable form. |
| du | -sh * | Show size of each item in the current directory. |
| top | | Live CPU and memory usage per process. Press q to quit. |
| ps | aux | List all running processes with user and CPU usage. |
| kill | -9 <pid> | Force-terminate a process by its PID. |
| killall | <app> | Force-quit a macOS app by name. E.g.: killall Finder |
| open | <path> | Open a file or URL in its default macOS app. |
| env | | Print all current environment variables. |
| export | VAR=value | Set an environment variable for the current shell session. |
| source | ~/.zshrc | Reload your shell config without opening a new terminal. |
| alias | | List all active shell aliases. |
| which | <cmd> | Show the filesystem path to an executable. |
| man | <cmd> | Open the manual page for any command. Press q to quit. |
| history | | Print your command history. Pipe to grep to search it. |
| pbcopy | | Pipe stdin to the clipboard. E.g.: cat file.txt \| pbcopy |
| pbpaste | | Paste clipboard contents to stdout. |
| curl | -s <url> | Fetch a URL and print the response. Pipe to jq for JSON. |
| ssh | user@host | Securely connect to a remote server over SSH. |
| scp | <src> user@host:<dest> | Securely copy files to or from a remote server. |
| ping | <host> | Test network connectivity. Press ⌃C to stop. |
| jq | '.<key>' file.json | Parse and filter JSON from the command line. |
| fd | <pattern> | Fast, friendly file finder. Faster alternative to find. |
| rg | <pattern> | Search file contents with ripgrep. --type ts to filter. |
| git | status\|add\|commit\|push\|pull | Core version control workflow. |
| git stash | push -m <name> | Save uncommitted changes with a name for later. |
| git log | --oneline --graph | Visual branch history in the terminal. |
| git restore | <file> | Discard unstaged changes to a specific file. |
| git switch | -c <branch> | Create and switch to a new branch (modern syntax). |
| git add | -p | Interactively stage hunks, not whole files. |
| git rebase | -i HEAD~<n> | Interactive rebase — squash or rename last N commits. |
| git diff | HEAD~1 -- <path> | Compare a specific path against the previous commit. |
| git tag | v1.0.0 | Tag a release. Push tags with: git push --tags |
| gh pr | create --fill | Create a pull request using the commit message as title. |
| gh pr | list | List all open pull requests in the repo. |
| gh pr | merge --squash | Squash-merge a pull request from the terminal. |
| gh pr | view --web | Open the current branch's pull request in the browser. |
| gh issue | create | File a bug or feature issue without leaving the terminal. |
| gh run | list | See CI/CD workflow runs for the current repo. |
| docker ps | | List currently running containers. |
| docker compose | up | Start all services defined in compose.yml. |
| docker compose | down | Stop and remove all running containers. |
| docker exec | -it <id> zsh | Open a shell inside a running container for debugging. |
| docker system | prune | Free disk space by clearing unused images and containers. |
| brew install | <tool> | Install a CLI tool via Homebrew. |
| brew upgrade | | Update all Homebrew-installed packages to latest versions. |
| brew list | | Show all packages installed via Homebrew. |
| brew doctor | | Diagnose common Homebrew issues. |
| brew services | list | See background services managed by Homebrew. |
| pnpm install | | Install project dependencies (faster, disk-efficient). |
| pnpm add | <pkg> | Add a dependency. Use -D for dev dependencies. |
| pnpm run | <script> | Run a package.json script. |
| pnpm storybook | | Start Storybook dev server on port 6006. |
| npm install | | Install dependencies from package.json (npm fallback). |
| node | --version | Verify your Node.js version (should be 20+ LTS). |
| nvm use | --lts | Switch to the latest Node.js LTS version. |
| pip install | <pkg> | Install a Python package or CLI tool. |
| python3 | -m http.server 8080 | Instant local server for any static folder. Zero config. |
| make run | | Start the dev environment (if Makefile defines run). |
| make build | | Run the production build via Makefile. |
| make test | | Run the test suite via Makefile. |
| make clean | | Remove build artefacts defined in the Makefile. |
| swift | build\|test\|run | Build, test, or run a Swift package. |
| claude | | Launch Claude Code in this terminal session. |
| exit | | Close the current terminal tab. |
