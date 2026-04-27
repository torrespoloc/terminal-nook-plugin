// Sources/SideNook/Views/NookToggle.swift
import SwiftUI

struct NookToggle: View {
    @Binding var isOn: Bool
    let theme: NookTheme

    private let trackWidth:        CGFloat = 28
    private let trackHeight:       CGFloat = 16
    private let trackCornerRadius: CGFloat = 8
    private let thumbSize:         CGFloat = 12
    private let thumbCornerRadius: CGFloat = 6

    private var thumbOffset: CGFloat { isOn ? 13 : 1 }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: trackCornerRadius, style: .continuous)
                .fill(isOn ? theme.accentReadable : theme.L1)
                .overlay(
                    Group {
                        if !isOn {
                            RoundedRectangle(cornerRadius: trackCornerRadius, style: .continuous)
                                .strokeBorder(theme.stroke2, lineWidth: 0.5)
                        }
                    }
                )
                .frame(width: trackWidth, height: trackHeight)

            RoundedRectangle(cornerRadius: thumbCornerRadius, style: .continuous)
                .fill(Color.white)
                .frame(width: thumbSize, height: thumbSize)
                .offset(x: thumbOffset)
                .animation(.easeInOut(duration: 0.15), value: isOn)
        }
        .frame(width: trackWidth, height: trackHeight)
        .contentShape(Rectangle())
        .onTapGesture { isOn.toggle() }
    }
}
