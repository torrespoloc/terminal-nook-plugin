// Sources/SideNook/Views/DragHandleView.swift
import SwiftUI
import AppKit

/// NSViewRepresentable that enables window dragging when used as a background.
/// The underlying NSView returns `mouseDownCanMoveWindow = true`, which works
/// in conjunction with `isMovableByWindowBackground = true` on the panel.
struct DragHandleView: NSViewRepresentable {
    func makeNSView(context: Context) -> DragHandleNSView {
        DragHandleNSView()
    }

    func updateNSView(_ nsView: DragHandleNSView, context: Context) {}
}

final class DragHandleNSView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }
}
