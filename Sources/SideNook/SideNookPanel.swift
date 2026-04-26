// Sources/SideNook/SideNookPanel.swift
import AppKit

@MainActor
final class SideNookPanel: NSPanel {

    var onDragEnd: (() -> Void)?

    override var canBecomeKey: Bool { true }

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)

        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
    }

    override func mouseDown(with event: NSEvent) {
        if !isKeyWindow {
            NSApp.activate(ignoringOtherApps: true)
            makeKey()
        }
        // Explicitly route focus to the hit view so Cmd+C/V reach SwiftTerm.
        // SwiftTerm doesn't override acceptsFirstMouse (defaults false), so
        // AppKit won't do this automatically on the first click.
        if let hit = contentView?.hitTest(event.locationInWindow),
           hit.acceptsFirstResponder {
            makeFirstResponder(hit)
        }
        super.mouseDown(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        onDragEnd?()
    }
}
