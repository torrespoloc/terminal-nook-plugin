// Sources/SideNook/Theme.swift
import SwiftUI

struct NookTheme {
    let isDark: Bool

    // ── Dark mode: absolute hex (NOT opacity over transparent).
    // Opacity-based layers composite over the NSPanel's clear background
    // and render as near-black. Absolute values are required.
    //
    // L0 #0d0e11  terminal background (deepest)
    // L1 #151720  panel shell
    // L2 #1d2030  nav bar / sidebar card
    // L3 #262a3d  settings popover / active tab

    static let darkL0 = Color(red: 0.051, green: 0.055, blue: 0.067) // #0d0e11
    static let darkL1 = Color(red: 0.082, green: 0.090, blue: 0.125) // #151720
    static let darkL2 = Color(red: 0.114, green: 0.125, blue: 0.188) // #1d2030
    static let darkL3 = Color(red: 0.149, green: 0.165, blue: 0.239) // #262a3d

    // ── Elevation layers ──────────────────────────────────────────────
    var L0: Color { isDark ? Self.darkL0 : Color(white: 0.96) }
    var L1: Color { isDark ? Self.darkL1 : Color(white: 0.97) }
    var L2: Color { isDark ? Self.darkL2 : Color(white: 0.92) }
    var L3: Color { isDark ? Self.darkL3 : Color(white: 0.985) }

    // ── Borders / strokes ─────────────────────────────────────────────
    // Strokes are opacity-based and go ON TOP of absolute layer colours — correct.
    var stroke0: Color { isDark ? .white.opacity(0.14) : .black.opacity(0.14) }
    var stroke1: Color { isDark ? .white.opacity(0.06) : .black.opacity(0.06) }
    var stroke2: Color { isDark ? .white.opacity(0.10) : .black.opacity(0.08) }
    var stroke3: Color { isDark ? .white.opacity(0.14) : .black.opacity(0.12) }

    // ── Foreground ────────────────────────────────────────────────────
    // Spec: fg = rgba(235,238,245, 0.92) | mute = rgba(200,205,220, 0.45)
    var fg:     Color { isDark ? Color(red: 0.922, green: 0.933, blue: 0.961).opacity(0.92)
                               : Color.black.opacity(0.88) }
    var fgMid:  Color { isDark ? Color(red: 0.922, green: 0.933, blue: 0.961).opacity(0.66)
                               : Color.black.opacity(0.62) }
    var fgMute: Color { isDark ? Color(red: 0.784, green: 0.804, blue: 0.863).opacity(0.45)
                               : Color.black.opacity(0.42) }

    // ── Highlights ────────────────────────────────────────────────────
    var innerHighlight: Color { isDark ? .white.opacity(0.06) : .white.opacity(0.90) }
    var gripDot:        Color { isDark ? .white.opacity(0.18) : .black.opacity(0.18) }

    // ── Control colours ───────────────────────────────────────────────
    // Row group bg: rgba(0,0,0,0.15) darkens inside L3 popover
    var groupBg:    Color { isDark ? Color.black.opacity(0.15) : Color.black.opacity(0.04) }
    // Toggle warm on-state
    var toggleWarm: Color { Color(red: 0.910, green: 0.710, blue: 0.420) } // #e8b56b
    // Danger (Quit)
    var danger:     Color { isDark ? Color(red: 0.957, green: 0.627, blue: 0.627)  // #f4a0a0
                                   : Color.red.opacity(0.80) }

    // ── Status dots ───────────────────────────────────────────────────
    var dotLive: Color { Color(red: 0.21, green: 0.82, blue: 0.50) } // #35d07f
    var dotAttn: Color { Color(red: 0.95, green: 0.71, blue: 0.18) } // #f0b429
    var dotDead: Color { .red.opacity(0.5) }
}
