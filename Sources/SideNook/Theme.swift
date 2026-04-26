// Sources/SideNook/Theme.swift
import SwiftUI
import AppKit

struct NookTheme {
    let isDark: Bool
    private let _accent: Color?

    init(isDark: Bool, accent: Color? = nil) {
        self.isDark = isDark
        self._accent = accent
    }

    // ── Dark mode: absolute hex (NOT opacity over transparent).
    // Opacity-based layers composite over the NSPanel's clear background
    // and render as near-black. Absolute values are required.
    //
    // L0 #282a30  terminal background (deepest)
    // L1 #151720  panel shell
    // L2 #1d2030  nav bar / sidebar card
    // L3 #262a3d  settings popover / active tab

    static let darkL0 = Color(red: 0.157, green: 0.165, blue: 0.188) // #282a30
    static let darkL1 = Color(red: 0.082, green: 0.090, blue: 0.125) // #151720
    static let darkL2 = Color(red: 0.114, green: 0.125, blue: 0.188) // #1d2030
    static let darkL3 = Color(red: 0.149, green: 0.165, blue: 0.239) // #262a3d

    // ── Elevation layers ──────────────────────────────────────────────
    var L0: Color { isDark ? Self.darkL0 : Color(white: 0.965, opacity: 0.98) }   // light: rgba(246,246,246,0.98)
    var L1: Color { isDark ? Self.darkL1 : Color.black.opacity(0.025) }            // light: rgba(0,0,0,0.025)
    var L2: Color { isDark ? Self.darkL2 : Color.white.opacity(0.62) }             // light: rgba(255,255,255,0.62)
    var L3: Color { isDark ? Self.darkL3 : Color.white.opacity(0.95) }             // light: rgba(255,255,255,0.95)

    // ── Borders / strokes ─────────────────────────────────────────────
    var stroke0: Color { isDark ? .white.opacity(0.14) : .black.opacity(0.14) }
    var stroke1: Color { isDark ? .white.opacity(0.06) : .black.opacity(0.06) }
    var stroke2: Color { isDark ? .white.opacity(0.10) : .black.opacity(0.08) }
    var stroke3: Color { isDark ? .white.opacity(0.14) : .black.opacity(0.12) }

    // ── Foreground ────────────────────────────────────────────────────
    var fg:     Color { isDark ? Color(red: 0.922, green: 0.933, blue: 0.961).opacity(0.92)
                               : Color.black.opacity(0.88) }
    var fgMid:  Color { isDark ? Color(red: 0.922, green: 0.933, blue: 0.961).opacity(0.66)
                               : Color.black.opacity(0.62) }
    var fgMute: Color { isDark ? Color(red: 0.784, green: 0.804, blue: 0.863).opacity(0.45)
                               : Color.black.opacity(0.42) }

    // ── Highlights ────────────────────────────────────────────────────
    var innerHighlight: Color { isDark ? .white.opacity(0.06) : .white.opacity(0.90) }

    // ── Accent ────────────────────────────────────────────────────────
    // Custom accent overrides the default phosphor green.
    // Default dark: #35d07f | Default light: accessible #1c7039 (~4.5:1 on white)
    var accent: Color {
        if let a = _accent { return a }
        return isDark ? Color(red: 0.208, green: 0.816, blue: 0.498)
                      : Color(red: 0.11,  green: 0.44,  blue: 0.23)
    }

    // ── Terminal background ───────────────────────────────────────────
    var termBg: Color { isDark ? Color(red: 0.157, green: 0.165, blue: 0.188)
                               : Color(red: 0.961, green: 0.961, blue: 0.957) }

    // ── Control colours ───────────────────────────────────────────────
    var groupBg: Color { isDark ? Color.black.opacity(0.15) : Color.black.opacity(0.04) }
    var danger:  Color { isDark ? Color(red: 0.957, green: 0.627, blue: 0.627)
                                : Color.red.opacity(0.80) }

    // ── Status dots ───────────────────────────────────────────────────
    var dotLive: Color { Color(red: 0.21,  green: 0.82,  blue: 0.50) }
    var dotAttn: Color { Color(red: 0.95,  green: 0.71,  blue: 0.18) }
    var dotDead: Color { Color(red: 0.973, green: 0.443, blue: 0.443, opacity: 0.60) }
}

// MARK: - Color ↔ Hex utilities
extension Color {
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s = String(s.dropFirst()) }
        guard s.count == 6, let value = UInt64(s, radix: 16) else { return nil }
        self.init(
            red:   Double((value >> 16) & 0xFF) / 255,
            green: Double((value >>  8) & 0xFF) / 255,
            blue:  Double( value        & 0xFF) / 255
        )
    }

    func hexString() -> String? {
        guard let c = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        let r = Int((c.redComponent   * 255).rounded())
        let g = Int((c.greenComponent * 255).rounded())
        let b = Int((c.blueComponent  * 255).rounded())
        return String(format: "#%02x%02x%02x", r, g, b)
    }
}
