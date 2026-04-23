# SideNook

A lightweight floating terminal panel for macOS. Lives as a slim pill on any screen edge — invisible until needed, then springs open on hover with a live shell session.

Works on all Spaces, fullscreen apps, and Mission Control. Never steals focus. Never clutters your Dock.

---

## Features

- **Hover to open** — pill sits flush against the screen edge; hover to expand, move away to collapse
- **Any edge** — dock to top, bottom, left, or right; drag to reposition
- **Resizable** — drag any free edge to resize the panel
- **Multi-tab** — up to 20 concurrent shell sessions with per-tab status indicators
- **Light & dark mode** — toggle appearance per session; ANSI colors tuned for both
- **Font size controls** — zoom in/out with keyboard shortcuts or the settings panel
- **Pin to stay open** — keep the panel expanded regardless of mouse position
- **Input highlight** — subtle highlight on rows where you submitted a command
- **Settings popover** — appearance, font size, dock position, and keyboard shortcuts reference
- **About panel** — version info and update instructions

---

## Requirements

- macOS 14 Sonoma or later
- Xcode Command Line Tools (`xcode-select --install`)

---

## Install

```bash
git clone https://github.com/torrespoloc/SideNook.git
cd SideNook
make install
```

This builds a release binary, assembles the `.app` bundle, copies it to `/Applications/`, and registers a login item so SideNook launches automatically at startup.

To remove it:

```bash
make uninstall
```

---

## Build & Run

```bash
make build      # Build release binary and assemble SideNook.app
make run        # Build and launch
make clean      # Remove build artifacts and app bundle
make install    # Install to /Applications + add login item
make uninstall  # Remove from /Applications and login items
```

---

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `⌘T` | New tab |
| `⌘W` | Close tab |
| `⌘⇧[` | Previous tab |
| `⌘⇧]` | Next tab |
| `⌘1` – `⌘9` | Jump to tab |
| `⌘K` | Clear screen |
| `⌘+` | Zoom in |
| `⌘−` | Zoom out |
| `⌘0` | Reset zoom |

---

## Project Structure

```
SideNook/
├── Sources/SideNook/
│   ├── main.swift                    # NSApplication entry point
│   ├── AppDelegate.swift             # Panel lifecycle, mouse + keyboard monitoring
│   ├── NookState.swift               # @Observable shared state
│   ├── SideNookPanel.swift           # NSPanel subclass (canBecomeKey)
│   ├── TrackingHostingView.swift     # NSHostingView + NSTrackingArea bridge
│   ├── EdgeDetection.swift           # Nearest screen edge geometry
│   ├── Models/
│   │   └── TerminalSession.swift     # PTY session, ANSI palettes, input tracking
│   ├── Terminal/
│   │   └── TerminalView.swift        # NSViewRepresentable wrapping SwiftTerm
│   └── Views/
│       ├── SideNookView.swift        # Root view — pill ↔ container, resize handles
│       ├── NavBarView.swift          # Tab bar, drag grip, action buttons
│       ├── TabButtonView.swift       # Individual tab with status dot + close
│       ├── TerminalContainerView.swift  # Terminal + input highlight layer
│       ├── InputHighlightOverlay.swift  # NSView that paints input-row bands
│       ├── DragHandleView.swift      # NSViewRepresentable for window dragging
│       ├── ResizeHandleView.swift    # Edge resize handles
│       ├── SettingsPopoverView.swift # Settings popover (appearance, font, position)
│       ├── ShortcutsListView.swift   # Keyboard shortcuts reference
│       └── AboutView.swift           # About panel
├── Resources/
│   └── Info.plist                    # Bundle metadata, LSUIElement
├── Tests/SideNookTests/              # Unit tests (NookState)
├── Package.swift                     # SPM manifest (SwiftTerm dependency)
├── Makefile                          # Build, run, install targets
└── PRD.md                            # Product requirements
```

---

## How It Works

SideNook runs as an `NSPanel` at `.floating` window level with `.canJoinAllSpaces` and `.fullScreenAuxiliary` collection behaviors. This makes it visible everywhere without ever appearing in the Dock or activating another app.

A global `NSEvent` monitor watches for mouse movement near the pill hit-test zone. When the cursor enters, the panel becomes key and SwiftUI animates the pill into the expanded container. A `TrackingHostingView` fires `mouseExited` to trigger the reverse.

The terminal is powered by [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) via `LocalProcessTerminalView`, running the user's login shell with `TERM=xterm-256color` and `COLORTERM=truecolor`.

---

## License

MIT — see [AboutView.swift](Sources/SideNook/Views/AboutView.swift) for details.
