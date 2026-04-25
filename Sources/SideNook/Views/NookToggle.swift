// Sources/SideNook/Views/NookToggle.swift
import SwiftUI

struct NookToggle: View {
    @Binding var isOn: Bool
    let isDark: Bool

    private var theme: NookTheme { NookTheme(isDark: isDark) }

    // Track dimensions
    private let trackWidth: CGFloat = 28
    private let trackHeight: CGFloat = 16
    private let trackCornerRadius: CGFloat = 8

    // Thumb dimensions
    private let thumbSize: CGFloat = 12
    private let thumbCornerRadius: CGFloat = 6

    // Thumb x-offset: 1px when off, 13px when on (left edge offset)
    private var thumbOffset: CGFloat {
        isOn ? 13 : 1
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Track
            RoundedRectangle(cornerRadius: trackCornerRadius, style: .continuous)
                .fill(isOn ? theme.accent : theme.L1)
                .overlay(
                    Group {
                        if !isOn {
                            RoundedRectangle(cornerRadius: trackCornerRadius, style: .continuous)
                                .strokeBorder(theme.stroke2, lineWidth: 0.5)
                        }
                    }
                )
                .frame(width: trackWidth, height: trackHeight)

            // Thumb
            RoundedRectangle(cornerRadius: thumbCornerRadius, style: .continuous)
                .fill(Color.white)
                .frame(width: thumbSize, height: thumbSize)
                .offset(x: thumbOffset)
                .animation(.easeInOut(duration: 0.15), value: isOn)
        }
        .frame(width: trackWidth, height: trackHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            isOn.toggle()
        }
    }
}
