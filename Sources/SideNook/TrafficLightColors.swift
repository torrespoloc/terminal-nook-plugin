// Sources/SideNook/TrafficLightColors.swift
import SwiftUI

extension Color {

    // MARK: - Active fills

    /// Close button fill — red.
    static let tlClose       = Color(hex: 0xFF5F57)
    /// Minimize button fill — amber.
    static let tlMinimize    = Color(hex: 0xFEBC2E)
    /// Fullscreen button fill — green.
    static let tlFullscreen  = Color(hex: 0x28C840)

    // MARK: - Active borders (1pt stroke inside each button)

    static let tlCloseBorder      = Color(hex: 0xE0443E)
    static let tlMinimizeBorder   = Color(hex: 0xD09B1A)
    static let tlFullscreenBorder = Color(hex: 0x1AAB29)

    // MARK: - Inactive state (window unfocused)

    static let tlInactive       = Color(hex: 0x9D9D9D)
    static let tlInactiveBorder = Color(hex: 0x828282)

    // MARK: - Hover glyphs (shown on all three buttons simultaneously)

    static let tlCloseGlyph      = Color(hex: 0x4D0000)
    static let tlMinimizeGlyph   = Color(hex: 0x985700)
    static let tlFullscreenGlyph = Color(hex: 0x006400)

    // MARK: - Hex helper

    private init(hex: UInt32) {
        self.init(
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255
        )
    }
}
