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
- Never hardcode colors in views. Always use `NookTheme` tokens via `state.theme`. Raw `Color(red:…)`, `Color.black.opacity(…)`, `Color.white.opacity(…)` literals belong only inside `Theme.swift` (the source of truth). If you need a new shade, add a token; do not inline it.
- Spacing follows the 8pt grid. Half-steps (4pt) only when visually warranted; 0.5pt strokes are intentional hairlines.
- All `@Observable` state lives in `NookState`. Don't create parallel state objects.
- Never start the PTY process in `init`. Always use `startProcessIfNeeded()`, which is called from `TerminalWrapperView.onFirstLayout` after SwiftUI layout has settled.

## Token Efficiency Rules

- NEVER explore broadly to diagnose. Read only the files directly named in the bug report.
- For diagnosis tasks: ask me which files to read if unsure. Max 3 files before reporting findings.
- Do not run parallel file sweeps unless explicitly asked.
- After identifying an issue, stop and report before fixing. Wait for approval.
- Prefer grep/search over full file reads when looking for a specific function or pattern.

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
`NookTheme` is computed from `NookState.theme` (never instantiated directly in views — always read via `state.theme`). Token catalogue:

**Surfaces / elevation**
- `L0` / `L1` / `L2` / `L3` — elevation layers (deepest to shallowest)
- `termBg` — terminal background (matches `L0` but absolute hex; SwiftTerm requires opaque)
- `groupBg` — grouped-control background (settings cards, code blocks)
- `glassBg` / `glassBgHover` — translucent overlay surfaces (e.g. scroll arrow buttons)
- `scrim` — modal/overlay dim layer

**Borders**
- `stroke0` / `stroke1` / `stroke2` / `stroke3` — increasing visual weight, all rendered at 0.5pt

**Foreground / labels**
- `fg` / `fgMid` / `fgMute` — label hierarchy
- `iconFg` / `iconFgMute` — icon-specific foregrounds (slightly different opacity curve than text)

**Interactive surfaces**
- `hoverBg` / `pressedBg` — universal hover and pressed background tints
- `innerHighlight` — top-edge shine on cards/buttons

**CTA (primary action)**
- `ctaBg` / `ctaBgHover` / `ctaFg` — sky-blue (`#ACDBE9`) family, used for "+" New Tab and the down-scroll arrow when content is waiting below

**Status / accent**
- `accent` — user pick (default phosphor green `#35d07f`)
- `accentReadable` — luminance-clamped accent that meets ≥4.5:1 on the active surface
- `defaultAccent` — the literal default green, for fallbacks
- `dotIdle` / `dotLive` / `dotAttn` / `dotDead` — session status dots
- `danger` — destructive actions (close on hover, etc.)

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

## Feature areas → files

Where to look first for each concern:

| Concern | File(s) | Key symbols |
|---|---|---|
| Panel state machine (pill ↔ expanded) | `Views/SideNookView.swift` · `NookState.swift` | `isExpanded`, `expand()`, `collapse()` |
| Pill UI | `Views/PillView.swift` | `PillView` |
| Expanded UI (layout selector) | `Views/ExpandedView.swift` | `ExpandedView`, `panelContent()` |
| Top-bar nav | `Views/NavBarView.swift` | `NavBarView`, `NavIconButton` |
| Left-sidebar nav | `Views/SidebarNavView.swift` | `SidebarNavView`, `SidebarTabRow` |
| Help panel resize drag | `Views/CommandLineHelpView.swift` L212–239 | `resizeHandle`, `DragGesture` |
| Window drag (move panel) | `Views/DragHandleView.swift` | `DragHandleView`, `mouseDownCanMoveWindow`; 18-line file — only enables panel move, zero resize logic |
| Edge resize handles | `Views/ResizeHandleView.swift` | `ResizeHandleView`, `ResizeEdge` (.right/.left/.top/.bottom); `ResizeHandleNSView` owns all drag math: mouseDown captures startPoint/startSize/startOrigin, mouseDragged computes dx/dy delta from screen coords, clamps to NookState.min/maxExpandedSize, updates state.expandedSize + state.panelPosition + window.setFrame live |
| Panel move enablement | `SideNookPanel.swift` | `isMovableByWindowBackground = true` (pairs with DragHandleView); `onDragEnd` callback fires on mouseUp; also routes focus to hit view on mouseDown |
| Pinning | `NookState.swift` · `Views/NavBarView.swift` · `Views/SidebarNavView.swift` | `isPinned`, `togglePin()` |
| Accent color + theming | `Theme.swift` · `NookState.swift` · `Views/SettingsPopoverView.swift` | `NookTheme.accent`, `accentHex` |
| Terminal rendering | `Terminal/TerminalView.swift` · `Views/TerminalContainerView.swift` | `TerminalSessionView`, `TerminalWrapperView` |
| Session lifecycle | `Models/TerminalSession.swift` · `NookState.swift` | `createSession()`, `closeSession()`, `activeSession` |
| Mouse monitoring / edge snap | `AppDelegate.swift` | `hitTestRect()`, `snapToNearestEdge()` |
| Custom traffic lights | `Views/TrafficLightButtonsView.swift` · `TrafficLightColors.swift` · `TrafficLightMetrics.swift` | `Color.tl*`, `TrafficLightMetrics.shared` |
| Settings UI | `Views/SettingsPopoverView.swift` | `SettingsPopoverView` |

## Keyboard shortcuts (AppDelegate)
Handled via a local `NSEvent` monitor (`keyCode`-based, not character-based):
`⌘T` new tab · `⌘W` close tab · `⌘{`/`⌘}` prev/next tab · `⌘1–9` jump to tab · `⌘K`/`⌘L` clear screen · `⌘,` settings · `⌘C` copy · `⌘V` paste · `⌘Z` send readline-undo (Ctrl+_) · `⌘Q` quit · `⌘+`/`⌘-`/`⌘0` font size · `⌘↑`/`⌘↓` scroll line · `⌘PageUp`/`⌘PageDown` scroll page · `⌘Home`/`⌘End` buffer limits · `⌃\`` global expand/collapse toggle (any app)

## What not to do
- Do not call `startProcess` directly — always use `startProcessIfNeeded()`.
- Do not add `hasShadow = true` — the system shadow is intentionally off; SwiftUI shadow is sole source.
- Do not use `.lineLimit` on help text in popovers — descriptions must wrap freely.
- Do not animate `panel.setFrame(animate:)`. The window frame is always `animate: false`; smooth transitions live inside SwiftUI (the contents animate, the frame snaps). Edge-snap state changes are wrapped in `withAnimation(.spring(...))` for the SwiftUI-side glide.
- Do not inline color literals in views — see "General rules" above.
- `Cmd+C` is explicitly intercepted in AppDelegate and calls `terminalView.copy()` — same pattern as paste. `Ctrl+C` interrupts through the PTY.
- Do not store session references outside `NookState.sessions` — session lifecycle is managed there.
- Do not reuse `nodeIds` or session IDs across app launches.
