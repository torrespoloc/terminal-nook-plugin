# Side Nook — Product Requirements Document

**Version:** 1.0  
**Date:** 2026-04-20  
**Status:** Draft  

---

## 1. Overview

Side Nook is a macOS utility that provides a persistent, ambient terminal sidebar accessible from any context — any app, any Space, any fullscreen. It mimics the feel of the iOS Volume HUD: invisible until needed, then snapping into view with a physical, tactile spring animation.

### Problem Statement

Developers and power users constantly switch between their primary app and a terminal. Alt-tabbing breaks flow. Full terminal windows consume screen real estate. There is no low-friction way to access a shell that stays out of the way when idle but is immediately reachable by muscle memory.

### Solution

A 6×120pt black pill lives permanently at the center-left edge of the screen. Hovering over it causes it to spring-expand into a 450×600pt terminal container. Moving away collapses it. The user never has to think about it — it's just there.

---

## 2. Goals

| Goal | Metric |
|---|---|
| Zero-friction terminal access | Hover-to-usable in < 300ms |
| Never in the way | Collapsed pill occupies < 6px of screen width |
| Works everywhere | Visible on all Spaces, fullscreen apps, Mission Control |
| Feels native | Animation indistinguishable from system HUDs |

---

## 3. Non-Goals

- Not a full terminal emulator replacement (no splits, profiles)
- Not a floating scratchpad or note-taking tool
- No menu bar icon or settings UI (v2)
- No tab reordering or split panes (v2)

---

## 4. User Stories

### Phase 1 — Frontend UI

> **Goal:** Ship a pixel-perfect, animated shell with no terminal functionality yet. Validate the feel before wiring the backend.

| ID | Story | Acceptance Criteria |
|---|---|---|
| UI-1 | As a user, I see a discreet black pill at the left screen edge at all times | Pill is 6×120pt, visible on all Spaces and fullscreen apps |
| UI-2 | As a user, hovering near the pill causes it to spring-expand | Expansion uses `interpolatingSpring(stiffness:280, damping:22)` — snappy, overshoots slightly |
| UI-3 | As a user, moving my mouse away collapses the nook | 250ms debounce prevents flicker; collapses only if cursor truly left the area |
| UI-4 | As a user, the nook looks physically premium | Deep black (96% opacity), 0.5pt white border at 10% opacity, stadium radius when collapsed, 22pt radius when expanded |
| UI-5 | As a user, the expanded nook shows a focused, dark content area | Content zone is clipped to 10pt inner radius; placeholder (black) until Phase 2 |
| UI-6 | As a user, the nook never activates another app or steals focus | NSPanel with `.nonactivatingPanel` style — no Dock bounce, no app switch |

### Phase 2 — Backend / Terminal

> **Goal:** Wire a live shell session into the expanded nook.

| ID | Story | Acceptance Criteria |
|---|---|---|
| BE-1 | As a user, the expanded nook shows an active terminal | Shell session (user's `$SHELL`) starts on launch; persists across expand/collapse cycles |
| BE-2 | As a user, I can type in the terminal when the nook is expanded | Keyboard events route to terminal only when expanded; blocked when collapsed |
| BE-3 | As a user, the terminal text renders in SF Mono | Font is `NSFont(name: "SF Mono", size: 13)` with monospaced fallback |
| BE-4 | As a user, the terminal has a dark, transparent background | Terminal bg is transparent; the nook's black fill shows through |
| BE-5 | As a user, the terminal resizes correctly when expanded | PTY SIGWINCH sent on resize; terminal reflows |

---

## 5. Technical Architecture

### Phase 1 — Frontend Only

```
SideNook.app (SPM executable)
├── main.swift                    # NSApplication entry
├── AppDelegate.swift             # Panel lifecycle, mouse monitoring
├── NookState.swift               # @Observable: isExpanded
├── SideNookPanel.swift           # NSPanel subclass (canBecomeKey)
├── TrackingHostingView.swift     # NSHostingView + NSTrackingArea bridge
└── Views/
    └── SideNookView.swift        # Pill ↔ container animation (no terminal)
```

**Key decisions:**
- Panel is always 460×650pt, transparent, positioned at x=0 center-left
- SwiftUI view animates width/height/cornerRadius; panel does not move
- `panel.ignoresMouseEvents = true` when collapsed; global `NSEvent` monitor watches for cursor in pill rect
- `panel.ignoresMouseEvents = false` when expanded; `NSTrackingArea` on `TrackingHostingView` fires `mouseExited`

### Phase 2 — Terminal Backend

```
└── Terminal/
    └── TerminalView.swift         # NSViewRepresentable wrapping SwiftTerm session
└── Views/
    └── TerminalContainerView.swift  # SwiftUI host for terminal, clipped
```

### Phase 3 — Interactive Features

```
├── Models/
│   └── TerminalSession.swift      # Session model owning PTY + terminal view
├── Views/
│   ├── NavBarView.swift           # Tab bar, drag grip, pin button, new tab
│   ├── TabButtonView.swift        # Individual tab with title + close
│   ├── DragHandleView.swift       # NSViewRepresentable for window dragging
│   └── ResizeHandleView.swift     # Edge resize handles
└── EdgeDetection.swift            # Nearest screen edge detection
```

**Key decisions:**
- SwiftTerm `LocalProcessTerminalView` manages PTY and process lifecycle
- Shell is user's `$SHELL -l` (login shell, inherits env)
- Terminal background set to transparent; nook fill is the visual bg
- `makeKey()` on expand; `resignKey()` on collapse for focus routing

---

## 6. UX Specification

### Collapsed State
| Property | Value |
|---|---|
| Width | 6pt |
| Height | 120pt |
| Corner radius | 60pt (stadium) |
| Fill | `Color.black.opacity(0.96)` |
| Border | `Color.white.opacity(0.10)`, 0.5pt |
| Mouse hit area | 14pt wide (ergonomic) |
| Panel hit-test | Off (`ignoresMouseEvents = true`) |

### Expanded State
| Property | Value |
|---|---|
| Width | 450pt |
| Height | 600pt |
| Corner radius | 22pt |
| Fill | Same as collapsed |
| Border | Same as collapsed |
| Shadow | Enabled |
| Panel hit-test | On (`ignoresMouseEvents = false`) |

### Animation
| Property | Value |
|---|---|
| API | `.interpolatingSpring(stiffness: 280, damping: 22)` |
| Triggered by | Global `NSEvent.mouseMoved` entering pill rect |
| Collapse delay | 250ms debounce; re-check cursor position before collapsing |
| Key window | `panel.makeKey()` on expand; `panel.resignKey()` on collapse |

---

## 7. Development Phases

### Phase 1: Frontend UI
**Deliverable:** `make run` launches the app. Pill is visible. Hover-to-expand works with spring animation. Collapse on mouse exit works. No terminal.

**Tasks:**
1. Project scaffold (Package.swift, Makefile, Info.plist)
2. NookState observable (TDD)
3. AppDelegate + main.swift
4. SideNookPanel subclass
5. TrackingHostingView
6. SideNookView (pill + animation, placeholder content area)

**Done when:** All 6 tasks pass review. `make run` produces a working pill animation on macOS 14+.

---

### Phase 2: Terminal Backend
**Deliverable:** `make run` produces a fully functional terminal nook. Shell session active. Typing works when expanded. Collapses cleanly.

**Tasks:**
7. TerminalView (SwiftTerm NSViewRepresentable)
8. TerminalContainerView + wire into SideNookView
9. Polish (keyboard focus, shadow, collapse debounce)
10. Login item install/uninstall (`make install`)

**Done when:** All 10 tasks pass review. End-to-end smoke test passes all 7 verification points.

---

### Phase 3: Interactive Features
**Deliverable:** Draggable, multi-edge, tabbed, resizable terminal panel with pin-to-stay.

**Features:**
11. Pin button — keeps panel expanded regardless of mouse position
12. Draggable panel — drag via nav bar to reposition
13. Resizable terminal — drag edges to resize independently (horizontal/vertical)
14. Screen edge adaptation — panel docks to nearest edge (left/right/top/bottom) with adaptive pill orientation and expansion direction
15. Tab bar with multiple terminal sessions — concurrent shells, auto-naming, plus/close buttons

**Done when:** All features work together. Panel can be dragged to any edge, pinned, resized, and multiple tabs operate independently.

---

## 8. Out of Scope (v2)

- Custom themes / color schemes
- Font size configuration
- Keyboard shortcut to expand (mouse-only)
- Settings UI
- Tab reordering (drag-to-reorder)
- Split terminal panes

---

## 9. Risks

| Risk | Mitigation |
|---|---|
| SPM executable → .app bundle lacks entitlements for PTY | Test early with `swift build` + manual bundle; add sandbox entitlements if needed |
| `NSEvent` global monitor requires Accessibility permission | Show a one-time prompt via `AXIsProcessTrustedWithOptions`; app is non-functional without it |
| SwiftTerm API changes between versions | Pin to `from: "1.2.0"`, test after `swift package resolve` |
| `interpolatingSpring` feels different on different macOS versions | Test on macOS 14 Sonoma (target) and 15 Sequoia |
