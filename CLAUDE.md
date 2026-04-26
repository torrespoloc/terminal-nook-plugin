# SideNook

## Project
Menu bar app for macOS. Main UI is an NSPanel subclass with no title bar (`.titled` not in styleMask). Native window chrome never appears. All window controls are custom SwiftUI views.

## Build & run
```
make run          # build release binary + assemble .app bundle + launch
swift build       # compile only (no .app assembly)
```
Entry point: `Sources/SideNook/main.swift`

## General rules
- Swift and SwiftUI only. No third-party packages unless explicitly approved (SwiftTerm is the only approved dependency).
- Follow Apple HIG for macOS.
- Never hardcode magic numbers — use named constants or values read from the system.
- All `@Observable` state lives in `NookState`. Don't create parallel state objects.
- Never start the PTY process in `init`. Always use `startProcessIfNeeded()`, which is called from `TerminalWrapperView.onFirstLayout` after SwiftUI layout has settled.

## Window controls
Traffic light buttons are custom SwiftUI drawn circles — never `NSWindowButton` or any native button.
- Geometry: always use `TrafficLightMetrics.shared`. Never hardcode pt values.
- Colors: always use `Color.tl*` from `TrafficLightColors.swift`. Never raw hex literals.
- Hover: one `onHover` on the `HStack` group, not per-button. All 3 glyphs appear together.
- Window active state: use `WindowActiveState` (`ObservableObject`) fed by `NSWindow` key notifications.

## Panel setup
`SideNookPanel` (`NSPanel` subclass) is created with `styleMask: [.borderless, .nonactivatingPanel]`.
- `backgroundColor = .clear`, `isOpaque = false`, `hasShadow = false`
- `level = .floating`, `collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]`
- Never add `.titled` — it breaks pill animation, edge-adaptive layout, and the transparent design.
- Shadow is applied via SwiftUI `.shadow()` only — never via `hasShadow`.

## Layout modes
Two tab layout modes, toggled via `state.tabLayout`:
- `.leftSidebar` — sidebar (180pt wide) on the left, terminal fills remaining width
- `.topBar` — horizontal nav bar (40pt tall) at top, terminal fills remaining height

Default panel size: 450×600pt. Width auto-adjusts to 720pt (topBar) or 820pt (leftSidebar) on mode switch.

## Terminal content size math
`NookState.terminalContentSize(for:)` computes the exact PTY dimensions — do not replicate this math elsewhere.
- `leftSidebar`: width = `expandedSize.width - 202` (8 lead + 180 sidebar + 6 HStack spacing + 8 trail), height = `expandedSize.height - 24`
- `topBar`: width = `expandedSize.width - 16`, height = `expandedSize.height - 78` (NavBar 54 + top 16 + bottom 8)

Always pass the result of `terminalContentSize(for:)` when creating a `TerminalSession`. The PTY column/row count must match the actual rendered size or output will wrap incorrectly.

## Theme system
`NookTheme` is computed from `NookState.theme` (never instantiated directly in views — always read via `state.theme`). Key tokens:
- `L0` / `L1` / `L2` / `L3` — elevation layers (deepest to shallowest)
- `fg` / `fgMid` / `fgMute` — label hierarchy
- `stroke1` / `stroke2` / `stroke3` — border weights (all 0.5pt)
- `accent` — phosphor green `#35d07f` default, user-selectable
- `innerHighlight` — top-edge shine on cards/buttons

Light mode is a first-class citizen. Every view must respond correctly to `state.isDark`.

## SwiftTerm constraints
SwiftTerm internals that are off-limits (package-private — do not access):
- `selection`, `hasSelectionRange` — cannot check selection state from outside
- `Buffer.yBase` — use `scrollUp/Down(lines: 50_000)` for buffer-limit scrolling instead

To send text input to a running shell, use `TerminalSession.send(text:)` — it calls `terminalView.send(data:)` on the PTY stdin without appending a newline.

## Key files
| File | Purpose |
|---|---|
| `AppDelegate.swift` | Panel lifecycle, mouse monitoring, edge-adaptive geometry, keyboard shortcuts |
| `NookState.swift` | All `@Observable` state; `terminalContentSize(for:)`; session management |
| `SideNookPanel.swift` | `NSPanel` subclass; focus routing; drag end callback |
| `Theme.swift` | `NookTheme` struct and all design tokens |
| `Models/TerminalSession.swift` | Session model owning PTY; `startProcessIfNeeded()` is idempotent and deferred |
| `Views/SideNookView.swift` | Root SwiftUI view — pill + expanded states + resize handles |
| `Views/NavBarView.swift` | Top-bar layout nav bar; tabs, drag grip, action buttons |
| `Views/SidebarNavView.swift` | Left-sidebar layout nav; drag grip, action buttons, tab list, help panel |
| `Views/TerminalContainerView.swift` | Terminal host view |
| `Views/CommandLineHelpView.swift` | Collapsible command reference panel (sidebar only); resizable, clickable rows |
| `Terminal/TerminalView.swift` | `NSViewRepresentable`; `TerminalWrapperView` uses `layout()` override + `onFirstLayout` callback |
| `_metadata/claude-design_UI-spec-handoff.md` | Complete design token and component spec (read-only reference) |

## Keyboard shortcuts (AppDelegate)
Handled via a local `NSEvent` monitor (`keyCode`-based, not character-based):
`⌘T` new tab · `⌘W` close tab · `⌘[`/`⌘]` prev/next tab · `⌘1–9` jump to tab · `⌘K` clear · `⌘+`/`⌘-`/`⌘0` font size · `⌘↑`/`⌘↓` scroll line · `⌘PageUp`/`⌘PageDown` scroll page · `⌘Home`/`⌘End` buffer limits

## What not to do
- Do not call `startProcess` directly — always use `startProcessIfNeeded()`.
- Do not add `hasShadow = true` — the system shadow is intentionally off; SwiftUI shadow is sole source.
- Do not use `.lineLimit` on help text in popovers — descriptions must wrap freely.
- Do not intercept `Cmd+C` — SwiftTerm handles copy natively; `Ctrl+C` interrupts through the PTY.
- Do not store session references outside `NookState.sessions` — session lifecycle is managed there.
- Do not reuse `nodeIds` or session IDs across app launches.
