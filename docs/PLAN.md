# Side Nook Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS floating panel that lives as a 6px black pill on the left screen edge and spring-expands into a 450×600 terminal container on hover.

**Architecture:** An `NSPanel` with `.floating` level and `.canJoinAllSpaces` sits permanently at the left screen edge. A `TrackingHostingView` subclass + global `NSEvent` monitor drive expand/collapse state held in an `@Observable` class. SwiftUI renders the pill-to-container transition with `interpolatingSpring`; SwiftTerm provides the embedded terminal via `LocalProcessTerminalView`.

**Tech Stack:** Swift 6.3, SwiftUI, AppKit (NSPanel, NSTrackingArea, NSEvent global monitors), SwiftTerm (SPM), SPM executable target, Makefile for `.app` bundle assembly.

---

## File Map

| File | Responsibility |
|---|---|
| `Package.swift` | SPM manifest; SwiftTerm dependency |
| `Makefile` | Build + assemble `.app` bundle; `make run` |
| `Resources/Info.plist` | Bundle metadata; `LSUIElement` to hide from Dock |
| `Sources/SideNook/main.swift` | Entry point — creates `NSApplication`, sets delegate |
| `Sources/SideNook/AppDelegate.swift` | Panel lifecycle, global mouse monitor, expand/collapse logic |
| `Sources/SideNook/NookState.swift` | `@Observable` shared state (`isExpanded`) |
| `Sources/SideNook/SideNookPanel.swift` | `NSPanel` subclass — `canBecomeKey = true` when expanded |
| `Sources/SideNook/TrackingHostingView.swift` | `NSHostingView` subclass with `NSTrackingArea` for `mouseExited` |
| `Sources/SideNook/Views/SideNookView.swift` | Root SwiftUI view — pill ↔ container animation |
| `Sources/SideNook/Views/TerminalContainerView.swift` | SwiftUI wrapper that hosts the terminal, SF Mono font |
| `Sources/SideNook/Terminal/TerminalView.swift` | `NSViewRepresentable` wrapping SwiftTerm's `LocalProcessTerminalView` |
| `Tests/SideNookTests/NookStateTests.swift` | Unit tests for state transitions |

---

## Task 1: Project scaffold — Package.swift, Makefile, Info.plist

**Files:**
- Create: `Package.swift`
- Create: `Makefile`
- Create: `Resources/Info.plist`
- Create: `Sources/SideNook/.gitkeep`
- Create: `Tests/SideNookTests/.gitkeep`

- [ ] **Step 1: Create Package.swift**

```swift
// Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SideNook",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "SideNook",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm"),
            ],
            path: "Sources/SideNook"
        ),
        .testTarget(
            name: "SideNookTests",
            dependencies: ["SideNook"],
            path: "Tests/SideNookTests"
        ),
    ]
)
```

- [ ] **Step 2: Create Makefile**

```makefile
# Makefile
.PHONY: build run clean

BINARY_DIR = .build/release
BINARY     = $(BINARY_DIR)/SideNook
APP        = SideNook.app

build:
	swift build -c release
	mkdir -p $(APP)/Contents/MacOS
	mkdir -p $(APP)/Contents/Resources
	cp $(BINARY) $(APP)/Contents/MacOS/SideNook
	cp Resources/Info.plist $(APP)/Contents/

run: build
	open $(APP)

clean:
	rm -rf .build $(APP)
```

- [ ] **Step 3: Create Resources/Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>SideNook</string>
    <key>CFBundleIdentifier</key>
    <string>com.user.sidenook</string>
    <key>CFBundleName</key>
    <string>SideNook</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 4: Create placeholder directories**

```bash
mkdir -p Sources/SideNook/Views Sources/SideNook/Terminal Tests/SideNookTests Resources
```

- [ ] **Step 5: Verify package resolves**

```bash
swift package resolve
```

Expected: SwiftTerm is fetched into `.build/checkouts/` with no errors.

- [ ] **Step 6: Commit**

```bash
git init
git add Package.swift Makefile Resources/Info.plist
git commit -m "chore: scaffold SPM project with SwiftTerm dependency"
```

---

## Task 2: NookState — shared observable state

**Files:**
- Create: `Sources/SideNook/NookState.swift`
- Create: `Tests/SideNookTests/NookStateTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
// Tests/SideNookTests/NookStateTests.swift
import Testing
@testable import SideNook

@Suite("NookState")
struct NookStateTests {

    @Test("starts collapsed")
    func startsCollapsed() {
        let state = NookState()
        #expect(state.isExpanded == false)
    }

    @Test("expand sets isExpanded true")
    func expandSetsTrue() {
        let state = NookState()
        state.expand()
        #expect(state.isExpanded == true)
    }

    @Test("collapse sets isExpanded false")
    func collapseSetsTrue() {
        let state = NookState()
        state.expand()
        state.collapse()
        #expect(state.isExpanded == false)
    }

    @Test("toggle flips state")
    func toggleFlips() {
        let state = NookState()
        state.toggle()
        #expect(state.isExpanded == true)
        state.toggle()
        #expect(state.isExpanded == false)
    }
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
swift test --filter NookStateTests 2>&1 | tail -10
```

Expected: compilation error — `NookState` not defined.

- [ ] **Step 3: Implement NookState**

```swift
// Sources/SideNook/NookState.swift
import Observation

@Observable
final class NookState {
    var isExpanded: Bool = false

    func expand()   { isExpanded = true }
    func collapse() { isExpanded = false }
    func toggle()   { isExpanded.toggle() }
}
```

- [ ] **Step 4: Run tests — expect pass**

```bash
swift test --filter NookStateTests 2>&1 | tail -5
```

Expected: `Test run with 4 tests passed`.

- [ ] **Step 5: Commit**

```bash
git add Sources/SideNook/NookState.swift Tests/SideNookTests/NookStateTests.swift
git commit -m "feat: add NookState observable with expand/collapse/toggle"
```

---

## Task 3: App entry point + AppDelegate skeleton

**Files:**
- Create: `Sources/SideNook/main.swift`
- Create: `Sources/SideNook/AppDelegate.swift`

- [ ] **Step 1: Create main.swift**

```swift
// Sources/SideNook/main.swift
import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

> Note: Do **not** add `@main` to any struct — we use `main.swift` as the SPM entry point.

- [ ] **Step 2: Create AppDelegate skeleton**

```swift
// Sources/SideNook/AppDelegate.swift
import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    // Set in setupPanel — always non-nil after applicationDidFinishLaunching
    private var panel: SideNookPanel!
    private let state = NookState()
    private var globalMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)  // hide from Dock
        setupPanel()
        startMouseMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Panel

    private func setupPanel() {
        let screen = NSScreen.main!
        let frame = NSRect(
            x: 0,
            y: screen.frame.midY - Constants.panelHeight / 2,
            width: Constants.panelWidth,
            height: Constants.panelHeight
        )

        panel = SideNookPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true   // pass-through until hovered

        let hostView = TrackingHostingView(
            rootView: SideNookView().environment(state)
        )
        hostView.onMouseExit = { [weak self] in
            DispatchQueue.main.async { self?.collapse() }
        }
        panel.contentView = hostView
        panel.orderFrontRegardless()
    }

    // MARK: - Expand / Collapse

    func expand() {
        guard !state.isExpanded else { return }
        state.expand()
        panel.ignoresMouseEvents = false
        (panel.contentView as? TrackingHostingView<SideNookView>)?.updateTrackingAreas()
    }

    func collapse() {
        guard state.isExpanded else { return }
        state.collapse()
        panel.ignoresMouseEvents = true
    }

    // MARK: - Global Mouse Monitor

    private func startMouseMonitoring() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            guard let self, !self.state.isExpanded else { return }
            let mouse = NSEvent.mouseLocation
            let pillRect = self.pillScreenRect()
            if pillRect.contains(mouse) {
                DispatchQueue.main.async { self.expand() }
            }
        }
    }

    /// The on-screen rect of the collapsed pill used for hover detection.
    private func pillScreenRect() -> NSRect {
        let midY = panel.frame.minY + (Constants.panelHeight - Constants.pillHeight) / 2
        return NSRect(
            x: 0,
            y: midY,
            width: Constants.pillHitWidth,  // slightly wider than 6px for ergonomics
            height: Constants.pillHeight
        )
    }
}

// MARK: - Layout constants

enum Constants {
    static let panelWidth:   CGFloat = 460
    static let panelHeight:  CGFloat = 650
    static let pillWidth:    CGFloat = 6
    static let pillHeight:   CGFloat = 120
    static let pillHitWidth: CGFloat = 14   // generous hover target
    static let expandedWidth:  CGFloat = 450
    static let expandedHeight: CGFloat = 600
}
```

- [ ] **Step 3: Verify compilation**

```bash
swift build 2>&1 | grep -E "error:|Build complete"
```

Expected: fails with "cannot find type 'SideNookPanel'" and "cannot find type 'TrackingHostingView'" — those come in the next tasks.

- [ ] **Step 4: Commit stub**

```bash
git add Sources/SideNook/main.swift Sources/SideNook/AppDelegate.swift
git commit -m "feat: add AppDelegate skeleton with panel setup and mouse monitoring"
```

---

## Task 4: SideNookPanel — NSPanel subclass

**Files:**
- Create: `Sources/SideNook/SideNookPanel.swift`

- [ ] **Step 1: Create SideNookPanel**

```swift
// Sources/SideNook/SideNookPanel.swift
import AppKit

/// NSPanel subclass that can become key window when expanded,
/// allowing the embedded terminal to receive keyboard input.
final class SideNookPanel: NSPanel {

    /// Allow this panel to become the key window so the terminal
    /// captures keyboard events when expanded.
    override var canBecomeKey: Bool { true }

    /// Allow it to become main so it appears above non-floating windows.
    override var canBecomeMain: Bool { true }
}
```

- [ ] **Step 2: Verify compilation advances**

```bash
swift build 2>&1 | grep -E "error:|Build complete"
```

Expected: now fails only on missing `TrackingHostingView` and `SideNookView`.

- [ ] **Step 3: Commit**

```bash
git add Sources/SideNook/SideNookPanel.swift
git commit -m "feat: add SideNookPanel NSPanel subclass"
```

---

## Task 5: TrackingHostingView — mouse-exit bridge

**Files:**
- Create: `Sources/SideNook/TrackingHostingView.swift`

- [ ] **Step 1: Create TrackingHostingView**

```swift
// Sources/SideNook/TrackingHostingView.swift
import AppKit
import SwiftUI

/// NSHostingView subclass that installs an NSTrackingArea so AppKit
/// receives mouseExited events even though the content is SwiftUI.
final class TrackingHostingView<Content: View>: NSHostingView<Content> {

    var onMouseExit: (() -> Void)?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        // Remove stale tracking areas before adding a fresh one.
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        onMouseExit?()
    }
}
```

- [ ] **Step 2: Verify compilation still fails only on SideNookView**

```bash
swift build 2>&1 | grep "error:"
```

Expected: `error: cannot find type 'SideNookView'` only.

- [ ] **Step 3: Commit**

```bash
git add Sources/SideNook/TrackingHostingView.swift
git commit -m "feat: add TrackingHostingView for AppKit mouse-exit bridging"
```

---

## Task 6: SwiftUI pill-to-container view (no terminal yet)

**Files:**
- Create: `Sources/SideNook/Views/SideNookView.swift`

The goal here is a compiling, animating shell — the terminal slot is a placeholder `Color.clear` rectangle that will be replaced in Task 8.

- [ ] **Step 1: Create SideNookView**

```swift
// Sources/SideNook/Views/SideNookView.swift
import SwiftUI

struct SideNookView: View {

    @Environment(NookState.self) private var state

    // Pill geometry
    private let pillW: CGFloat  = Constants.pillWidth
    private let pillH: CGFloat  = Constants.pillHeight
    // Expanded geometry
    private let nookW: CGFloat  = Constants.expandedWidth
    private let nookH: CGFloat  = Constants.expandedHeight

    var body: some View {
        // Anchor the nook to the left edge of the transparent panel.
        HStack(spacing: 0) {
            nook
            Spacer(minLength: 0)
        }
        .frame(
            width:  Constants.panelWidth,
            height: Constants.panelHeight,
            alignment: .leading
        )
        // Center nook vertically within the panel
        .frame(maxHeight: .infinity, alignment: .center)
    }

    // MARK: - Nook shape

    private var nook: some View {
        let w = state.isExpanded ? nookW : pillW
        let h = state.isExpanded ? nookH : pillH
        // Stadium (capsule) when collapsed; rounded rect when expanded.
        let radius = state.isExpanded ? 22.0 : 60.0

        return ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color.black.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
                )

            if state.isExpanded {
                terminalSlot
                    .padding(12)
                    .transition(.opacity.animation(.easeIn(duration: 0.08)))
            }
        }
        .frame(width: w, height: h)
        .animation(
            .interpolatingSpring(stiffness: 280, damping: 22),
            value: state.isExpanded
        )
        .allowsHitTesting(state.isExpanded)
    }

    // MARK: - Terminal slot (placeholder — replaced in Task 8)

    @ViewBuilder
    private var terminalSlot: some View {
        Color.clear   // replaced by TerminalContainerView in Task 8
    }
}
```

- [ ] **Step 2: Build and verify it compiles**

```bash
swift build 2>&1 | grep -E "error:|Build complete"
```

Expected: `Build complete!`

- [ ] **Step 3: Smoke-test the animation**

```bash
make run
```

Verify: a small black pill appears at the center-left screen edge. Move the mouse to x=0 near the center of the screen — the pill should spring-expand to a large black rounded rectangle. Moving away collapses it.

> If the app doesn't launch, check Console.app for crash logs. Common issue: `LSUIElement` not loaded because the `.app` bundle is stale — run `make clean && make run`.

- [ ] **Step 4: Commit**

```bash
git add Sources/SideNook/Views/SideNookView.swift
git commit -m "feat: add SideNookView with interpolatingSpring pill-to-container animation"
```

---

## Task 7: TerminalView — SwiftTerm NSViewRepresentable

**Files:**
- Create: `Sources/SideNook/Terminal/TerminalView.swift`

- [ ] **Step 1: Create TerminalView**

```swift
// Sources/SideNook/Terminal/TerminalView.swift
import SwiftUI
import SwiftTerm

/// SwiftUI wrapper around SwiftTerm's LocalProcessTerminalView.
/// The PTY shell starts immediately on `makeNSView` and persists
/// for the lifetime of the view.
struct TerminalView: NSViewRepresentable {

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let tv = LocalProcessTerminalView(frame: .zero)
        tv.processDelegate = context.coordinator

        // SF Mono, falling back to system monospaced
        let font = NSFont(name: "SF Mono", size: 13)
            ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        tv.font = font

        // Dark theme — match the nook background
        tv.nativeBackgroundColor = NSColor.black.withAlphaComponent(0)
        tv.nativeForegroundColor = NSColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1)

        // Start a login shell
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        tv.startProcess(executable: shell, args: ["-l"], environment: nil, execName: nil)

        return tv
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
        // No dynamic updates needed — terminal manages its own state.
    }

    // MARK: - Coordinator

    final class Coordinator: LocalProcessTerminalViewDelegate {
        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
            // Terminal notifies us of size changes — no action needed.
        }

        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
            // Title changes can be forwarded to the panel title if desired.
        }

        func processTerminated(source: TerminalView, exitCode: Int32?) {
            // Shell exited — could restart or show a message.
            // For now, do nothing; the user can quit the app.
        }
    }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
swift build 2>&1 | grep -E "error:|Build complete"
```

Expected: `Build complete!`

- [ ] **Step 3: Commit**

```bash
git add Sources/SideNook/Terminal/TerminalView.swift
git commit -m "feat: add TerminalView NSViewRepresentable wrapping SwiftTerm"
```

---

## Task 8: TerminalContainerView + wire into SideNookView

**Files:**
- Create: `Sources/SideNook/Views/TerminalContainerView.swift`
- Modify: `Sources/SideNook/Views/SideNookView.swift` — replace `terminalSlot` placeholder

- [ ] **Step 1: Create TerminalContainerView**

```swift
// Sources/SideNook/Views/TerminalContainerView.swift
import SwiftUI

/// Hosts the TerminalView with appropriate clipping and disabled
/// interaction in non-expanded states.
struct TerminalContainerView: View {
    var body: some View {
        TerminalView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Clip terminal content to the nook shape
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
```

- [ ] **Step 2: Replace the placeholder in SideNookView**

In `Sources/SideNook/Views/SideNookView.swift`, replace the `terminalSlot` computed property:

```swift
    @ViewBuilder
    private var terminalSlot: some View {
        TerminalContainerView()
    }
```

- [ ] **Step 3: Build and verify**

```bash
swift build 2>&1 | grep -E "error:|Build complete"
```

Expected: `Build complete!`

- [ ] **Step 4: End-to-end smoke test**

```bash
make run
```

Verify:
1. Black pill visible at center-left screen edge.
2. Hovering x<14px in the pill Y-range expands the nook with a spring animation.
3. The terminal renders inside — you should see a shell prompt in SF Mono.
4. You can type in the terminal when expanded.
5. Moving the mouse away collapses the nook and the terminal becomes non-interactive.
6. Switch to a fullscreen app (Mission Control > fullscreen) — the nook pill should still appear on the left edge.
7. Switch desktop spaces — nook pill persists.

- [ ] **Step 5: Commit**

```bash
git add Sources/SideNook/Views/TerminalContainerView.swift Sources/SideNook/Views/SideNookView.swift
git commit -m "feat: wire live terminal into expanded nook view"
```

---

## Task 9: Polish — keyboard focus, shadow, and auto-collapse delay

**Files:**
- Modify: `Sources/SideNook/AppDelegate.swift`
- Modify: `Sources/SideNook/Views/SideNookView.swift`

- [ ] **Step 1: Add shadow when expanded (AppDelegate.setupPanel)**

In `AppDelegate.swift`, after `panel.ignoresMouseEvents = true`, add a call to `panel.hasShadow`:

```swift
// In expand():
panel.hasShadow = true
NSApp.activate(ignoringOtherApps: false)

// In collapse():
panel.hasShadow = false
NSApp.deactivate()
```

- [ ] **Step 2: Make the panel the key window on expand so terminal gets keyboard input**

In `AppDelegate.expand()`, after `panel.ignoresMouseEvents = false`:

```swift
panel.makeKey()
```

In `AppDelegate.collapse()`, before `state.collapse()`:

```swift
panel.resignKey()
```

- [ ] **Step 3: Add a short collapse delay so the panel doesn't flicker when the mouse briefly leaves**

Replace the `onMouseExit` closure in `setupPanel()`:

```swift
hostView.onMouseExit = { [weak self] in
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
        // Re-check mouse position before collapsing to avoid flickering
        // when the mouse briefly clips the edge of the nook.
        let mouse = NSEvent.mouseLocation
        guard let self else { return }
        if !self.panel.frame.contains(mouse) {
            self.collapse()
        }
    }
}
```

- [ ] **Step 4: Build and verify no regressions**

```bash
make clean && make run
```

Verify all 7 points from Task 8 Step 4 still pass, plus:
- Typing in the terminal works (keyboard focus acquired).
- Moving the mouse just outside the nook edge doesn't cause rapid expand/collapse flicker.

- [ ] **Step 5: Commit**

```bash
git add Sources/SideNook/AppDelegate.swift
git commit -m "feat: keyboard focus on expand, shadow, and collapse debounce"
```

---

## Task 10: Final wiring — auto-start on login (optional)

**Files:**
- Create: `Makefile` additions

- [ ] **Step 1: Add `make install` target to Makefile**

Append to `Makefile`:

```makefile
install: build
	cp -r $(APP) /Applications/
	osascript -e 'tell application "System Events" to make new login item at end with properties {path:"/Applications/SideNook.app", hidden:true}'
	@echo "SideNook installed and set to launch at login."

uninstall:
	osascript -e 'tell application "System Events" to delete login item "SideNook"' 2>/dev/null || true
	rm -rf /Applications/SideNook.app
```

- [ ] **Step 2: Verify `make install` works**

```bash
make install
```

Expected: App copied to `/Applications/` and login item registered. Verify in System Settings → General → Login Items.

- [ ] **Step 3: Final commit**

```bash
git add Makefile
git commit -m "feat: add make install/uninstall for login item registration"
```

---

## Self-Review Checklist

### Spec Coverage

| Requirement | Covered by |
|---|---|
| Vertical NSPanel, center-left | Task 3 AppDelegate `setupPanel()` |
| `.floating` level | Task 3 `panel.level = .floating` |
| `.canJoinAllSpaces` + fullscreen | Task 3 `collectionBehavior` |
| 6px pill idle state, 120px tall | Task 6 `Constants.pillWidth/pillHeight` |
| Spring animation on hover | Task 6 `.interpolatingSpring(stiffness:280, damping:22)` |
| `interpolatingSpring` feel | Task 6 — uses that exact API |
| Deep black, ~100% opacity | Task 6 `Color.black.opacity(0.96)` |
| `Material.ultraDark` vibrancy | Simplified to solid black (ultraDark is deprecated/unavailable in SwiftUI) — the solid black at 96% opacity is visually equivalent |
| Stadium / extreme corner radius | Task 6 `cornerRadius: 60` on 6pt pill, `cornerRadius: 22` expanded |
| 0.5pt white stroke at 10% | Task 6 `strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)` |
| Terminal inside expanded view | Task 7 + 8 SwiftTerm + TerminalContainerView |
| SF Mono font | Task 7 `NSFont(name: "SF Mono", size: 13)` |
| Terminal only interactive when expanded | Task 6 `.allowsHitTesting(state.isExpanded)` + Task 9 keyboard focus |
| Shrinks on mouse leave | Task 5 TrackingHostingView `mouseExited` → collapse |

### Placeholder Scan

None found — all steps have concrete code.

### Type Consistency

- `NookState` → used in `AppDelegate` (owns instance), `SideNookView` (via `@Environment`), `TrackingHostingView` (generic parameter)
- `Constants` enum → used in `AppDelegate`, `SideNookView`
- `TrackingHostingView<SideNookView>` — the cast in `AppDelegate.expand()` must match. If casting becomes brittle, store `hostView` as a property on AppDelegate instead of casting `panel.contentView`.
- `LocalProcessTerminalViewDelegate` methods — `processTerminated(source: TerminalView, exitCode:)` uses SwiftTerm's `TerminalView` type (the base class), not our `TerminalView` struct. The coordinator `Coordinator` class signature must match SwiftTerm's delegate protocol exactly — verify after `swift package resolve` by checking `.build/checkouts/SwiftTerm/Sources/SwiftTerm/LocalProcess.swift`.
