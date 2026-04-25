// Sources/SideNook/Views/SideNookView.swift
import SwiftUI

/// Top-level view — coordinates exactly two states: pill (rest) and expanded (full UI).
/// All visual logic lives in PillView and ExpandedView respectively.
struct SideNookView: View {
    @Bindable var state: NookState

    var body: some View {
        ZStack {
            if state.isExpanded {
                ExpandedView(state: state)
                    .transition(.opacity)
            } else {
                PillView(state: state)
                    .transition(.opacity)
            }
        }
        // Single animation gate — both views fade as one unit, no internal delays.
        // easeOut on enter (ExpandedView decelerates in); easeIn on exit (PillView accelerates out).
        // 140ms sits in the micro-interaction range and doesn't delay task completion.
        .animation(
            state.reduceMotion ? .linear(duration: 0) : .easeOut(duration: 0.14),
            value: state.isExpanded
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
