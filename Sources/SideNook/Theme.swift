// Sources/SideNook/Theme.swift
import SwiftUI

struct NookTheme {
    let isDark: Bool

    // ── Elevation layers (L0 = base, L3 = highest) ───────────
    var L0: Color { isDark ? .black.opacity(0.96)          : Color(white: 0.965) }
    var L1: Color { isDark ? .white.opacity(0.035)         : .black.opacity(0.025) }
    var L2: Color { isDark ? .white.opacity(0.06)          : .white.opacity(0.62) }
    var L3: Color { isDark ? .white.opacity(0.095)         : .white.opacity(0.95) }

    // ── Borders / strokes ─────────────────────────────────────
    var stroke0: Color { isDark ? .white.opacity(0.14)  : .black.opacity(0.14) }
    var stroke1: Color { isDark ? .white.opacity(0.06)  : .black.opacity(0.06) }
    var stroke2: Color { isDark ? .white.opacity(0.085) : .black.opacity(0.08) }
    var stroke3: Color { isDark ? .white.opacity(0.13)  : .black.opacity(0.12) }

    // ── Foreground ────────────────────────────────────────────
    var fg:     Color { isDark ? .white.opacity(0.92)  : .black.opacity(0.88) }
    var fgMid:  Color { isDark ? .white.opacity(0.66)  : .black.opacity(0.62) }
    var fgMute: Color { isDark ? .white.opacity(0.42)  : .black.opacity(0.42) }

    // ── Highlights ────────────────────────────────────────────
    var innerHighlight: Color { isDark ? .white.opacity(0.06) : .white.opacity(0.90) }
    var gripDot:        Color { isDark ? .white.opacity(0.15) : .black.opacity(0.15) }

    // ── Status dots ───────────────────────────────────────────
    var dotLive: Color { Color(red: 0.21, green: 0.82, blue: 0.50) } // #35d07f
    var dotAttn: Color { Color(red: 0.95, green: 0.71, blue: 0.18) } // #f0b429 amber
    var dotDead: Color { .red.opacity(0.5) }
}
