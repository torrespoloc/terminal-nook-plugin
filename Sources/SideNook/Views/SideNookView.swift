// Sources/SideNook/Views/SideNookView.swift
import SwiftUI

struct SideNookView: View {
    @Bindable var state: NookState

    var body: some View {
        Group {
            if state.isExpanded {
                expandedView
            } else {
                collapsedView
            }
        }
        .animation(
            .interpolatingSpring(stiffness: 280, damping: 22),
            value: state.isExpanded
        )
    }

    private var collapsedView: some View {
        Capsule()
            .fill(Color.black)
            .frame(width: 6, height: 120)
    }

    private var expandedView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(white: 0.12))
            .frame(width: 450, height: 600)
            .overlay(
                Text("Terminal goes here")
                    .foregroundStyle(.white)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
            )
    }
}
